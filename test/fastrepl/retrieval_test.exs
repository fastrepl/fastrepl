defmodule Fastrepl.RetrievalTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval

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
end
