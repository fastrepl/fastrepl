defmodule Mix.Tasks.Modify do
  use Mix.Task

  def run(args) do
    Mix.Task.run("app.start")

    case args do
      [path, line_start, line_end, instruction] ->
        file = Fastrepl.Repository.File.from!(Application.fetch_env!(:fastrepl, :root), path)

        comments = [
          %Fastrepl.Repository.Comment{
            file_path: file.path,
            line_start: String.to_integer(line_start),
            line_end: String.to_integer(line_end),
            content: instruction
          }
        ]

        case Fastrepl.SemanticFunction.Modify.run(file, comments) do
          {:ok, modified_file} ->
            modified_file_path = Path.join(System.tmp_dir!(), Nanoid.generate())
            File.write!(modified_file_path, modified_file.content)

            {stdout, _} =
              System.cmd("git", [
                "diff",
                "--color=always",
                "--no-index",
                file.path,
                modified_file_path
              ])

            IO.puts(stdout)

          {:error, message} ->
            IO.puts("#{IO.ANSI.red()}#{message}")
        end

      _ ->
        IO.puts("#{IO.ANSI.cyan()}mix modify <PATH> <LINE_START> <LINE_END> <INSTRUCTION>")
    end
  end
end
