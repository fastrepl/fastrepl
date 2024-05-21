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
