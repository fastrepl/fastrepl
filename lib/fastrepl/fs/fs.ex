defmodule Fastrepl.FS do
  require Logger

  alias Fastrepl.Github
  alias Fastrepl.Native.CodeUtils

  def clone(repo_full_name, commit_sha, auth_token \\ nil) do
    clone_url =
      case auth_token do
        nil -> Github.URL.clone_without_token(repo_full_name)
        _ -> Github.URL.clone_with_token(repo_full_name, auth_token)
      end

    repo_id = String.replace(repo_full_name, "/", "-")

    dir =
      Application.fetch_env!(:fastrepl, :clone_dir)
      |> Path.join("#{repo_id}-#{commit_sha}")

    cond do
      File.exists?(dir) -> {:ok, dir}
      CodeUtils.clone_commit(clone_url, dir, commit_sha) -> {:ok, dir}
      true -> {:error, "failed to clone repo"}
    end
  end

  def list_files(root) do
    is_hidden = &String.starts_with?(Path.basename(&1), ".")

    walk_dir(root, fn
      {:dir, path} ->
        path = Path.relative_to(path, root)
        not is_hidden.(path)

      {:file, _} ->
        true
    end)
  end

  def list_informative_files(root, ignore_patterns \\ []) do
    is_hidden = &String.starts_with?(Path.basename(&1), ".")
    is_banned_dir = &(Path.basename(&1) in ["node_modules", "dist", "venv", "_next"])
    is_banned_filename = &(Path.basename(&1) in ["package-lock.json", "LICENSE"])

    is_banned_extension =
      &(Path.extname(&1) in [
          ".lock",
          ".pyc",
          ".ipynb",
          ".log",
          ".css",
          ".txt",
          ".html",
          ".txt",
          ".log",
          ".ini",
          ".jsonl"
        ])

    is_media_extension =
      &(Path.extname(&1) in [
          ".mp3",
          ".mp4",
          ".png",
          ".jpg",
          ".jpeg",
          ".gif",
          ".webp",
          ".wav",
          ".svg"
        ])

    is_ignored_by_config =
      &Enum.any?(
        ignore_patterns,
        fn pattern -> CodeUtils.glob_match(&1, pattern) end
      )

    walk_dir(root, fn
      {:dir, path} ->
        path = Path.relative_to(path, root)

        Enum.all?([
          not is_hidden.(path),
          not is_banned_dir.(path),
          not is_ignored_by_config.(path)
        ])

      {:file, path} ->
        path = Path.relative_to(path, root)

        Enum.all?([
          not is_hidden.(path),
          not is_banned_extension.(path),
          not is_banned_filename.(path),
          not is_media_extension.(path),
          not is_ignored_by_config.(path)
        ])
    end)
  end

  def read_lines!(path, {line_from, line_to}) do
    line_from = max(1, line_from)

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
