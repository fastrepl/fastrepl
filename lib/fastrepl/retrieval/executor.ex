defmodule Fastrepl.Retrieval.Executor do
  use Tracing

  alias Fastrepl.Retrieval.Context
  alias Fastrepl.Retrieval.Result

  @spec run(Context.t(), [map()]) :: {Context.t(), [Result.t()]}
  def run(%Context{} = retrieval_ctx, plans) do
    Tracing.span %{}, "executor" do
      ctx = Tracing.current_ctx()

      tasks =
        plans
        |> Enum.map(fn %{name: name, args: args} ->
          tool = Enum.find(retrieval_ctx.tools, fn tool -> tool.name() == name end)

          if tool do
            Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
              Tracing.attach_ctx(ctx)
              tool.run(retrieval_ctx, args)
            end)
          else
            nil
          end
        end)
        |> Enum.reject(&is_nil/1)

      results =
        tasks
        |> Enum.flat_map(fn task ->
          case Task.yield(task, 10 * 1000) || Task.shutdown(task) do
            {:ok, result} -> result
            _ -> []
          end
        end)

      {ctx, results}
    end
  end
end
