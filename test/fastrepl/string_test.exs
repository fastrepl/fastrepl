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
end
