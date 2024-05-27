defmodule Fastrepl.Retrieval.Planner do
  use Tracing

  alias Fastrepl.Github
  alias Fastrepl.Renderer
  alias Fastrepl.Retrieval.Context

  @models [
    "gpt-4o",
    "claude-3-haiku"
  ]

  @spec run(Context.t(), Github.Issue.t()) :: {Context.t(), [map()]}
  def run(%Context{} = ctx, issue) do
    messages = [
      %{
        role: "system",
        content: """
        You are a helpful code retrieval planner.
        """
      },
      %{
        role: "user",
        content: """
        #{Renderer.Github.render_issue(issue)}
        ---

        Based on the issue above, use tools to retrieve code snippets that are useful to understand or solve the issue.
        Use as many tools as needed.
        """
      }
    ]

    result = request(ctx.tools, messages)
    {ctx, result}
  end

  defp request(tools, messages) do
    Tracing.span %{}, "planner" do
      ctx = Tracing.current_ctx()

      tasks =
        @models
        |> Enum.map(fn model ->
          Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
            Tracing.attach_ctx(ctx)

            llm(
              %{
                model: model,
                messages: messages,
                temperature: 0.5,
                tools: Enum.map(tools, & &1.schema()),
                tool_choice: "required"
              },
              otel_attrs: %{model: model}
            )
          end)
        end)

      tasks
      |> Enum.flat_map(fn task ->
        case Task.yield(task, 6 * 1000) || Task.shutdown(task) do
          {:ok, result} -> result
          _ -> []
        end
      end)
    end
  end

  def llm(request, opts \\ []) do
    case Fastrepl.AI.chat(request, opts) do
      {:ok, tool_calls} -> tool_calls
      {:error, _} -> []
    end
  end
end
