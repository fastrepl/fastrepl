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
