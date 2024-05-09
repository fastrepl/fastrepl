defmodule Fastrepl.String do
  defmodule Levenshtein do
    @moduledoc """
    https://github.com/preciz/levenshtein/blob/914f4d144032c7853215f4051512d99ae6c3be33/README.md?plain=1#L7-L8
    """
    def distance(source, target)

    def distance(source, source), do: 0

    def distance(source, <<>>), do: String.length(source)

    def distance(<<>>, target), do: String.length(target)

    def distance(source, target) do
      source = String.graphemes(source)
      target = String.graphemes(target)
      distlist = 0..Kernel.length(target) |> Enum.to_list()
      do_distance(source, target, distlist, 1)
    end

    defp do_distance([], _, distlist, _), do: List.last(distlist)

    defp do_distance([src_hd | src_tl], target, distlist, step) do
      distlist = distlist(target, distlist, src_hd, [step], step)
      do_distance(src_tl, target, distlist, step + 1)
    end

    defp distlist([], _, _, new_distlist, _), do: Enum.reverse(new_distlist)

    defp distlist(
           [target_hd | target_tl],
           [distlist_hd | distlist_tl],
           grapheme,
           new_distlist,
           last_dist
         ) do
      diff = if target_hd != grapheme, do: 1, else: 0
      min = min(min(last_dist + 1, hd(distlist_tl) + 1), distlist_hd + diff)
      distlist(target_tl, distlist_tl, grapheme, [min | new_distlist], min)
    end
  end

  def levenshtein_distance(source, target) do
    Levenshtein.distance(source, target)
  end

  @spec levenshtein_distance_normalized(String.t(), String.t()) :: float()
  def levenshtein_distance_normalized("", ""), do: 1.0

  def levenshtein_distance_normalized(source, target) do
    max_length = max(String.length(source), String.length(target))
    1.0 - levenshtein_distance(source, target) / max_length
  end

  @spec find_code_block(String.t(), String.t()) :: {pos_integer(), pos_integer()}
  def find_code_block(query, code) do
    spans =
      query
      |> String.split(~r/\s*\n\s*\.\.\.\s*\n/)
      |> Enum.map(&find_best_overlap(&1, code))

    line_start = Enum.min_by(spans, fn {line, _} -> line end) |> elem(0)
    line_end = Enum.max_by(spans, fn {_, line} -> line end) |> elem(1)

    {line_start, line_end}
  end

  defp find_best_overlap(query, code) when is_binary(query) and is_binary(code) do
    find_best_overlap(String.split(query, "\n"), String.split(code, "\n"), 0, 0, -1)
  end

  defp find_best_overlap(query_lines, [], _, best_index, _) do
    {best_index + 1, best_index + 1 + length(query_lines)}
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
        0.8 * levenshtein_distance_normalized(a, b)
    end
  end
end
