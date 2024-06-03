defmodule Fastrepl.Retrieval.CodeBlock do
  @spec find(String.t(), String.t()) :: {pos_integer(), pos_integer()} | nil
  def find(query, code) do
    spans =
      query
      |> String.split(~r/\s*\n\s*\.\.\.\s*\n/)
      |> Enum.map(&find_best_overlap(&1, code))
      |> Enum.reject(&is_nil/1)

    if Enum.empty?(spans) do
      nil
    else
      {
        Enum.min_by(spans, fn {line, _} -> line end) |> elem(0),
        Enum.max_by(spans, fn {_, line} -> line end) |> elem(1)
      }
    end
  end

  defp find_best_overlap(query, code) when is_binary(query) and is_binary(code) do
    find_best_overlap(String.split(query, "\n"), String.split(code, "\n"), 0, 0, -1)
  end

  defp find_best_overlap(query_lines, [], _, best_index, score) do
    if score > 0.2 do
      {best_index + 1, best_index + length(query_lines)}
    else
      nil
    end
  end

  defp find_best_overlap(
         query_lines,
         [_ | code_lines_rest] = code_lines,
         current_index,
         best_index,
         best_score
       ) do
    current_score =
      Enum.zip(query_lines, code_lines)
      |> Enum.map(fn {q, c} -> compare_line(q, c) end)
      |> Enum.sum()
      |> Kernel./(length(query_lines))

    if current_score > best_score do
      find_best_overlap(
        query_lines,
        code_lines_rest,
        current_index + 1,
        current_index,
        current_score
      )
    else
      find_best_overlap(
        query_lines,
        code_lines_rest,
        current_index + 1,
        best_index,
        best_score
      )
    end
  end

  defp compare_line(a, b) when is_binary(a) and is_binary(b) do
    len_a = String.length(a)
    len_b = String.length(b)

    cond do
      a == b ->
        1

      String.trim_leading(a) == String.trim_leading(b) ->
        0.9 - abs(len_a - len_b) / (len_a + len_b)

      String.trim(a) == String.trim(b) ->
        0.8 - abs(len_a - len_b) / (len_a + len_b)

      true ->
        0.8 * Fastrepl.String.levenshtein_distance_normalized(a, b)
    end
  end
end
