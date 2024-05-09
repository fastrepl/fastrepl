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

  describe "find_code_block/2" do
    test "full code match" do
      query = """
      function hello() {
        console.log("hello");
      }
      """

      code = """
      const a = 1;

      function hello() {
        console.log("!");
      }

      function world() {
        console.log("!");
      }

      const b = 2;
      """

      match = Fastrepl.String.find_code_block(String.trim(query), String.trim(code))
      assert match == {3, 6}
    end

    test "full code almost match" do
      query = """
      const hello = () => {
            console.log(" !");
      }
      """

      code = """
      const a = 1;

      function hello() {
        console.log("!");
      }

      function world() {
        console.log("!");
      }

      const b = 2;
      """

      match = Fastrepl.String.find_code_block(String.trim(query), String.trim(code))
      assert match == {3, 6}
    end

    test "handle ellipsis" do
      query = """
      const hello = () => {
        console.log("!");
        ...
        console.log("*");
      }
      """

      code = """
      const a = 1;
      const c = 2;

      function world() {
        console.log("world");
      }

      function hello() {
        console.log("!");
        console.log("%");
        console.log("?");
        console.log("#");
        console.log("*");
      }

      const b = 2;
      """

      match = Fastrepl.String.find_code_block(String.trim(query), String.trim(code))
      assert match == {8, 15}
    end
  end
end
