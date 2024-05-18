defmodule Tracing do
  @moduledoc """
  Mostly copied from https://github.com/msramos/abstracing/blob/main/lib/tracing.ex
  """

  OpenTelemetry.Tracer

  defguard is_ast(value) when is_tuple(value) and tuple_size(value) == 3
  defguard valid_opts(opts) when is_map(opts) or is_ast(opts)
  defguard valid_name(name) when is_binary(name) or is_nil(name) or is_ast(name)

  defmacro __using__(_opts) do
    quote do
      require OpenTelemetry.Tracer
      require OpenTelemetry.Ctx

      require unquote(__MODULE__)
      import unquote(__MODULE__), only: [span: 1, span: 2, span: 3]
    end
  end

  def current_ctx() do
    OpenTelemetry.Ctx.get_current()
  end

  def attach_ctx(ctx) do
    OpenTelemetry.Ctx.attach(ctx)
  end

  defmacro span(start_opts \\ quote(do: %{}), name \\ nil, do: block)
           when valid_opts(start_opts) and valid_name(name) do
    name = name || gen_span_name(__CALLER__)

    quote do
      __MODULE__
      |> :opentelemetry.get_application_tracer()
      |> :otel_tracer.with_span(
        unquote(name),
        unquote(start_opts),
        fn ctx ->
          try do
            unquote(block)
          rescue
            e ->
              type =
                e
                |> Map.get(:__struct__)
                |> to_string()
                |> String.replace("Elixir.", "")

              attrs = %{
                "type" => type,
                "message" => Exception.message(e),
                "stacktrace" => Exception.format_stacktrace(__STACKTRACE__)
              }

              Tracing.set_attributes("exception", attrs)
              OpenTelemetry.Tracer.set_status(:error, "exception")
              :otel_span.end_span(ctx)
              reraise e, __STACKTRACE__
          end
        end
      )
    end
  end

  defp gen_span_name(caller) do
    {function, arity} = caller.function

    base_name =
      caller.module
      |> Atom.to_string()
      |> String.replace("Elixir.", "")
      |> String.replace("/", ".")

    base_name <> ".#{function}/#{arity}"
  end

  @spec build_span_opts(Keyword.t()) :: map()
  def build_span_opts(opts \\ []) do
    opts
    |> Keyword.take([:kind, :attributes, :links, :start_time, :is_recording])
    |> Map.new()
  end

  # Simple guard to detect if a variable is a set of values or not
  defguardp is_set(value) when is_map(value) or is_list(value) or is_tuple(value)

  @spec end_span(:opentelemetry.timestamp() | :undefined) ::
          :opentelemetry.span_ctx() | :undefined
  defdelegate end_span(timestamp \\ :undefined), to: OpenTelemetry.Tracer

  defmacro start_span(name, opts) do
    opts =
      opts
      |> enumerable_to_attrs()
      |> Macro.escape()

    quote bind_quoted: [name: name, start_opts: opts] do
      __MODULE__
      |> :opentelemetry.get_application_tracer()
      |> :otel_tracer.start_span(
        name,
        Map.new(start_opts)
      )
    end
  end

  defmacro start_span(ctx, name, opts) do
    opts =
      opts
      |> enumerable_to_attrs()
      |> Macro.escape()

    quote bind_quoted: [ctx: ctx, name: name, start_opts: opts] do
      :otel_tracer.start_span(
        ctx,
        :opentelemetry.get_application_tracer(__MODULE__),
        name,
        Map.new(start_opts)
      )
    end
  end

  @spec set_current_span(:opentelemetry.span_ctx() | :undefined) ::
          :opentelemetry.span_ctx() | :undefined
  defdelegate set_current_span(span_context), to: OpenTelemetry.Tracer

  @spec set_current_span(:otel_ctx.t(), :opentelemetry.span_ctx() | :undefined) :: :otel_ctx.t()
  defdelegate set_current_span(context, span_context), to: OpenTelemetry.Tracer

  @spec set_status(OpenTelemetry.status() | OpenTelemetry.status_code(), String.t()) :: boolean()
  def set_status(status_or_status_code, description \\ "")

  def set_status(status, _description) when is_tuple(status) do
    OpenTelemetry.Tracer.set_status(status)
  end

  def set_status(status_code, description) do
    OpenTelemetry.Tracer.set_status(status_code, description)
  end

  defmacro with_span(name, start_opts \\ quote(do: %{}), do: block) do
    quote do
      __MODULE__
      |> :opentelemetry.get_application_tracer()
      |> :otel_tracer.with_span(
        unquote(name),
        Map.new(unquote(start_opts)),
        fn _arg -> unquote(block) end
      )
    end
  end

  defmacro with_span(ctx, name, start_opts, do: block) do
    start_opts =
      start_opts
      |> enumerable_to_attrs()
      |> Macro.escape()

    quote do
      :otel_tracer.with_span(
        unquote(ctx),
        :opentelemetry.get_application_tracer(__MODULE__),
        unquote(name),
        Map.new(unquote(start_opts)),
        fn _arg -> unquote(block) end
      )
    end
  end

  @spec current_span_ctx() :: :opentelemetry.span_ctx() | :undefined
  defdelegate current_span_ctx, to: OpenTelemetry.Tracer

  @spec current_span_ctx(:otel_ctx.t()) :: :opentelemetry.span_ctx() | :undefined
  defdelegate current_span_ctx(context), to: OpenTelemetry.Tracer

  @spec set_attribute(OpenTelemetry.attribute_key(), OpenTelemetry.attribute_value()) :: boolean()
  def set_attribute(key, value)

  def set_attribute(key, value) when is_set(value) do
    set_attributes(key, value)
  end

  def set_attribute(key, value) do
    OpenTelemetry.Tracer.set_attribute(key, value)
  end

  @spec set_attributes(OpenTelemetry.attribute_key(), map() | list() | tuple()) :: boolean()
  def set_attributes(key, values) do
    key
    |> enumerable_to_attrs(values)
    |> OpenTelemetry.Tracer.set_attributes()
  end

  @spec add_event(OpenTelemetry.event_name(), OpenTelemetry.attributes_map()) :: boolean
  def add_event(name, attributes \\ %{}) do
    :otel_span.add_event(
      :otel_tracer.current_span_ctx(),
      name,
      attributes
    )
  end

  @spec add_events([OpenTelemetry.event()]) :: boolean()
  defdelegate add_events(events), to: OpenTelemetry.Tracer

  @spec record_exception(Exception.t(), any(), any()) :: boolean
  defdelegate record_exception(exception, trace \\ nil, attributes \\ []),
    to: OpenTelemetry.Tracer

  @spec update_name(String.t()) :: boolean()
  defdelegate update_name(name), to: OpenTelemetry.Tracer

  defp enumerable_to_attrs(enumerable)

  defp enumerable_to_attrs(s) when is_struct(s) do
    enumerable_to_attrs(Map.from_struct(s))
  end

  defp enumerable_to_attrs(enumerable) when is_map(enumerable) or is_list(enumerable) do
    enumerable
    |> Enum.with_index()
    |> Map.new(fn
      {{key, value}, _index} ->
        {key, inspect(value)}

      {value, index} ->
        {index, inspect(value)}
    end)
  end

  defp enumerable_to_attrs(enumerable) when is_tuple(enumerable) do
    enumerable_to_attrs(Tuple.to_list(enumerable))
  end

  defp enumerable_to_attrs(name, enumerable)

  defp enumerable_to_attrs(name, s) when is_struct(s) do
    enumerable_to_attrs(name, Map.from_struct(s))
  end

  defp enumerable_to_attrs(name, enumerable) when is_map(enumerable) or is_list(enumerable) do
    enumerable
    |> Enum.with_index()
    |> Map.new(fn
      {{key, _value} = item, index} when is_set(key) ->
        {"#{name}.#{index}", inspect(item)}

      {{key, value}, _index} ->
        {"#{name}.#{key}", inspect(value)}

      {value, index} ->
        {"#{name}.#{index}", inspect(value)}
    end)
  end

  defp enumerable_to_attrs(name, enumerable) when is_tuple(enumerable) do
    enumerable_to_attrs(name, Tuple.to_list(enumerable))
  end
end
