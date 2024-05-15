defmodule Fastrepl.Retrieval.Result do
  defstruct [:file_path, :file_content, :spans]

  alias __MODULE__
  alias Fastrepl.Retrieval.Chunker.Chunk

  @type t :: %Result{
          file_path: String.t(),
          file_content: String.t(),
          spans: [{pos_integer(), pos_integer()}]
        }

  def from!(%Chunk{} = chunk) do
    %Result{
      file_path: chunk.file_path,
      file_content: File.read!(chunk.file_path),
      spans: [chunk.span]
    }
  end

  def from!(path) when is_binary(path) do
    %Result{
      file_path: path,
      file_content: File.read!(path),
      spans: []
    }
  end

  def from!(path, lines) when is_list(lines) do
    %Result{
      file_path: path,
      file_content: File.read!(path),
      spans: lines |> Enum.map(fn num -> {num, num + 1} end)
    }
  end

  def fuse(results, options) when is_list(results) do
    results
    |> Enum.reduce([], fn %{file_path: file_path, spans: spans} = result, acc ->
      case acc do
        [%{file_path: ^file_path, spans: existing_spans} = head | tail] ->
          [%{head | spans: existing_spans ++ spans} | tail]

        _ ->
          [result | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.map(&fuse(&1, options))
  end

  def fuse(%Result{spans: spans} = result, options) do
    spans = spans |> Enum.sort_by(fn {start, _end} -> start end)
    %Result{result | spans: fuse(spans, [], options)}
  end

  defp fuse([current | rest], [], options), do: fuse(rest, [current], options)
  defp fuse([], acc, _), do: Enum.reverse(acc)

  defp fuse([{current_start, current_end} | rest], [{prev_start, prev_end} | _] = prev, options) do
    min_distance = Keyword.get(options, :min_distance, 20)

    if current_start - prev_end <= min_distance do
      updated_prev = [{prev_start, max(prev_end, current_end)} | Enum.drop(prev, 1)]
      fuse(rest, updated_prev, options)
    else
      fuse(rest, [{current_start, current_end} | prev], options)
    end
  end
end
