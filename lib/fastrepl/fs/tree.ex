defmodule Fastrepl.FS.Tree do
  defstruct name: "", path: "", children: []

  alias __MODULE__
  @type t :: %__MODULE__{name: String.t(), path: String.t(), children: [t()]}

  def build(paths) do
    paths
    |> Enum.map(&Path.split/1)
    |> Enum.reduce([], &build(&1, &2, ""))
  end

  defp build([filename], acc, current_path) do
    case Enum.find_index(acc, &(&1.name == filename)) do
      nil -> acc ++ [%Tree{name: filename, path: Path.join(current_path, filename)}]
      _ -> acc
    end
  end

  defp build([dirname | path], acc, current_path) do
    case Enum.find_index(acc, &(&1.name == dirname)) do
      nil ->
        acc ++
          [
            %Tree{
              name: dirname,
              path: Path.join(current_path, dirname),
              children: build(path, [], Path.join(current_path, dirname))
            }
          ]

      index ->
        {node, acc} = List.pop_at(acc, index)
        updated_children = build(path, node.children, Path.join(current_path, dirname))
        List.insert_at(acc, index, %Tree{node | children: updated_children})
    end
  end

  def render(nodes) when is_list(nodes) do
    nodes
    |> Enum.map(&render/1)
    |> Enum.join("\n")
  end

  def render(%Tree{} = tree) do
    render(tree, 0)
  end

  defp render(%Tree{name: name, children: []}, level) do
    indent = String.duplicate("  ", level)
    "#{indent}#{name}\n"
  end

  defp render(%Tree{name: name, children: children}, level) do
    indent = String.duplicate("  ", level)
    child_lines = Enum.map(children, &render(&1, level + 1))
    "#{indent}#{name}\n#{Enum.join(child_lines)}"
  end
end
