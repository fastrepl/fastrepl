defmodule Fastrepl.StringTest do
  use ExUnit.Case, async: true

  describe "levenshtein_distance_normalized/2" do
    test "exact" do
      actual = Fastrepl.String.levenshtein_distance_normalized("hello", "hello")
      assert_in_delta actual, 1.0, 0.001
    end

    test "similar" do
      actual = Fastrepl.String.levenshtein_distance_normalized("hello", "hell")
      assert_in_delta actual, 0.8, 0.001
    end

    test "different" do
      actual = Fastrepl.String.levenshtein_distance_normalized("hello", "world")
      assert_in_delta actual, 0.2, 0.001
    end
  end

  describe "read_lines!/2" do
    test "simple" do
      s = 1..100 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      assert Fastrepl.String.read_lines!(s, {4, 12}) == "4\n5\n6\n7\n8\n9\n10\n11\n12\n"
    end
  end
end
