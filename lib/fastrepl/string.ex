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

  def read_lines!(s, {line_from, line_to}) do
    {:ok, stream} = StringIO.open(s)

    stream
    |> IO.binstream(:line)
    |> Stream.drop(line_from - 1)
    |> Stream.take(line_to - line_from + 1)
    |> Enum.join()
  end
end
