defmodule Fastrepl.Retrieval.Executor do
  alias Fastrepl.Retrieval.Context
  alias Fastrepl.Retrieval.Result

  @spec run(Context.t(), map()) :: {Context.t(), [Result.t()]}
  def run(%Context{} = ctx, plans) do
    tasks =
      plans
      |> Enum.map(fn %{name: name, args: args} ->
        tool = Enum.find(ctx.tools, fn tool -> tool.name() == name end)

        if tool do
          Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
            tool.run(ctx, args)
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
