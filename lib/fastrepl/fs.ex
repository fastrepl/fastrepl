defmodule Fastrepl.FS do
  require Logger

  def git_clone(clone_url, path) do
    File.rm_rf(path)

    case System.cmd("git", ["clone", clone_url, path, "--depth=1", "--quiet"]) do
      {_, 0} ->
        :ok

      {_, code} ->
        Logger.error("Failed to clone repo. code: #{code}")
        File.rm_rf(path)
        :error
    end
  end

  def build_tree(paths) do
    paths
    |> Enum.map(&Path.split/1)
    |> Enum.reduce([], &build_tree(&1, &2, ""))
  end

  defp build_tree([filename], acc, current_path) do
    case Enum.find_index(acc, &(&1.name == filename)) do
      nil -> acc ++ [%{name: filename, path: Path.join(current_path, filename)}]
      _ -> acc
    end
  end

  defp build_tree([dirname | path], acc, current_path) do
    case Enum.find_index(acc, &(&1.name == dirname)) do
      nil ->
        acc ++
          [
            %{
              name: dirname,
              children: build_tree(path, [], Path.join(current_path, dirname)),
              path: Path.join(current_path, dirname)
            }
          ]

      index ->
        {node, acc} = List.pop_at(acc, index)
        updated_children = build_tree(path, node.children, Path.join(current_path, dirname))
        List.insert_at(acc, index, %{node | children: updated_children})
    end
  end

  def list_informative_files(root) do
    is_hidden = &String.starts_with?(Path.basename(&1), ".")
    is_banned_dir = &(Path.basename(&1) in ["node_modules", "dist", "venv"])
    is_banned_extension = &(Path.extname(&1) in ["", ".lock", ".pyc", ".ipynb"])
    is_banned_filename = &(Path.basename(&1) in ["package-lock.json"])
    is_media_extension = &(Path.extname(&1) in [".mp4", ".png", ".jpg", ".gif"])

    walk_dir(root, fn
      {:dir, path} ->
        path = Path.relative_to(path, root)

        Enum.all?([
          not is_hidden.(path),
          not is_banned_dir.(path)
        ])

      {:file, path} ->
        path = Path.relative_to(path, root)

        Enum.all?([
          not is_hidden.(path),
          not is_banned_extension.(path),
          not is_banned_filename.(path),
          not is_media_extension.(path)
        ])
    end)
  end

  def read_lines(path, {line_from, line_to}) do
    File.stream!(path, :line)
    |> Stream.drop(line_from - 1)
    |> Stream.take(line_to - line_from + 1)
    |> Enum.join()
  end

  def search_paths(root, query) do
    walk_dir(root, fn
      {:dir, _} ->
        true

      {:file, path} ->
        path = Path.relative_to(path, root)

        String.contains?(
          String.downcase(path),
          String.downcase(query)
        )
    end)
    |> Enum.map(&Path.relative_to(&1, root))
  end

  defp walk_dir(root, cb, acc \\ []) do
    File.ls!(root)
    |> Enum.reduce(acc, fn path, acc ->
      path = Path.join(root, path)

      cond do
        File.dir?(path) ->
          if cb.({:dir, path}) do
            walk_dir(path, cb, acc)
          else
            acc
          end

        true ->
          if cb.({:file, path}) do
            [path | acc]
          else
            acc
          end
      end
    end)
  end
end
