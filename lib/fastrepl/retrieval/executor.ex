defmodule Fastrepl.Retrieval.Executor do
  require Logger

  @spec run({[module()], [map()]}, map()) :: [map()]
  def run({tools, calls}, context) do
    tasks =
      calls
      |> Enum.map(fn {name, args} ->
        tool = Enum.find(tools, fn tool -> tool.as_function().name == name end)

        if tool do
          Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
            tool.run(args, context)
          end)
        else
          Logger.error("tool not found: #{name}")
          nil
        end
      end)
      |> Enum.reject(&is_nil/1)

    tasks
    |> Enum.flat_map(fn task ->
      case Task.yield(task, 10 * 1000) || Task.shutdown(task) do
        {:ok, result} ->
          result

        {:exit, reason} ->
          Logger.error("failed to execute a tool: #{inspect(reason)}")
          []
      end
    end)
  end
end
