defmodule Fastrepl.FS do
  require Logger

  alias Fastrepl.Native.CodeUtils

  def new_repo(repo_url, repo_full_name, repo_sha) do
    repo_id = String.replace(repo_full_name, "/", "-")

    dir =
      Application.fetch_env!(:fastrepl, :clone_dir)
      |> Path.join("#{repo_id}-#{repo_sha}")

    cond do
      File.exists?(dir) -> {:ok, dir}
      CodeUtils.clone(repo_url, dir, 1) -> {:ok, dir}
      true -> {:error, "failed to clone repo"}
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
    is_banned_dir = &(Path.basename(&1) in ["node_modules", "dist", "venv", "_next"])
    is_banned_filename = &(Path.basename(&1) in ["package-lock.json"])

    is_banned_extension =
      &(Path.extname(&1) in [
          "",
          ".lock",
          ".pyc",
          ".ipynb",
          ".log",
          ".json",
          ".css",
          ".txt",
          ".html"
        ])

    is_media_extension =
      &(Path.extname(&1) in [
          ".mp3",
          ".mp4",
          ".png",
          ".jpg",
          ".gif",
          ".webp",
          ".wav",
          ".svg"
        ])

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

  def read_lines!(path, {line_from, line_to}) do
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
          path |> Path.basename() |> String.downcase(),
          query |> String.downcase()
        )
    end)
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
