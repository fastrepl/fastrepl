defmodule Fastrepl.RetrievalTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval
  alias Fastrepl.FS

  describe "Result.fuse/1" do
    test "1" do
      actual =
        [
          %Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{1, 8}]},
          %Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{4, 20}]},
          %Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{25, 30}]},
          %Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{60, 80}]},
          %Retrieval.Result{file_path: "b.py", file_content: "b", spans: [{1, 8}]}
        ]
        |> Retrieval.Result.fuse(min_distance: 10)

      expected = [
        %Fastrepl.Retrieval.Result{
          file_path: "a.py",
          file_content: "a",
          spans: [{1, 30}, {60, 80}]
        },
        %Fastrepl.Retrieval.Result{
          file_path: "b.py",
          file_content: "b",
          spans: [{1, 8}]
        }
      ]

      assert actual == expected
    end
  end

  describe "Result.to_string/1" do
    test "1" do
      actual = %Retrieval.Result{
        file_path: "a.py",
        file_content: 1..20 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n"),
        spans: [{1, 2}, {6, 7}, {18, 20}]
      }

      assert actual |> to_string() ==
               """
               ```a.py
               1
               2
               ...
               6
               7
               ...
               18
               19
               20
               ```
               """
               |> String.trim()
    end
  end

  describe "Reranker.run/1" do
    test "it works with fuse" do
      actual =
        [
          %Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{1, 2}]},
          %Retrieval.Result{file_path: "b.py", file_content: "b", spans: [{3, 4}]},
          %Retrieval.Result{file_path: "b.py", file_content: "b", spans: [{5, 6}]},
          %Retrieval.Result{file_path: "b.py", file_content: "b", spans: [{7, 8}]},
          %Retrieval.Result{file_path: "c.py", file_content: "c", spans: [{9, 10}]},
          %Retrieval.Result{file_path: "c.py", file_content: "c", spans: [{11, 12}]}
        ]
        |> Retrieval.Reranker.run()
        |> Retrieval.Result.fuse(min_distance: 10)

      expected = [
        %Fastrepl.Retrieval.Result{file_path: "b.py", file_content: "b", spans: [{3, 8}]},
        %Fastrepl.Retrieval.Result{file_path: "c.py", file_content: "c", spans: [{9, 12}]},
        %Fastrepl.Retrieval.Result{file_path: "a.py", file_content: "a", spans: [{1, 2}]}
      ]

      assert actual == expected
    end
  end

  describe "CodeBlock.find/2" do
    test "full code match" do
      query = """
      function hello() {
        console.log("!");
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

      match = Retrieval.CodeBlock.find(String.trim(query), String.trim(code))
      assert match == {3, 5}
    end

    test "full code almost match" do
      query = """
      const hello = () => {
            console.log(" hi");
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

      match = Retrieval.CodeBlock.find(String.trim(query), String.trim(code))
      assert match == {3, 5}
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

      match = Retrieval.CodeBlock.find(String.trim(query), String.trim(code))
      assert match == {8, 14}
    end

    test "wrong query" do
      query = """
      123
      """

      code = """
      444
      555
      """

      match = Retrieval.CodeBlock.find(String.trim(query), String.trim(code))
      assert match == nil
    end
  end

  test "Context.from/1" do
    {:ok, root_dir} = FS.clone("BerriAI/litellm", "3167bee25aaae02f166c5048931d752580e10042")
    context = Retrieval.Context.from(root_dir)

    assert context.chunks |> Enum.count() > 100
    assert context.paths |> Enum.count() > 100
  end
end
