defmodule Fastrepl.FileTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Repository.File

  describe "replace/4" do
    test "start" do
      file = %File{
        path: "test.js",
        content:
          """
          a = 1;
          b = 2;
          c = 3;
          d = 4;
          e = 5;
          f = 6;
          """
          |> String.trim()
      }

      new_file = file |> File.replace(1, 2, ["a = 2;"])

      assert new_file.content ==
               """
               a = 2;
               b = 2;
               c = 3;
               d = 4;
               e = 5;
               f = 6;
               """
               |> String.trim()
    end

    test "middle" do
      file = %File{
        path: "test.js",
        content:
          """
          a = 1;
          b = 2;
          c = 3;
          d = 4;
          e = 5;
          f = 6;
          """
          |> String.trim()
      }

      new_file = file |> File.replace(3, 5, ["c = 4;", "d = 5;"])

      assert new_file.content ==
               """
               a = 1;
               b = 2;
               c = 4;
               d = 5;
               e = 5;
               f = 6;
               """
               |> String.trim()
    end

    test "end" do
      file = %File{
        path: "test.js",
        content:
          """
          a = 1;
          b = 2;
          c = 3;
          d = 4;
          e = 5;
          f = 6;
          """
          |> String.trim()
      }

      new_file = file |> File.replace(5, 7, ["e = 6;", "f = 7;"])

      assert new_file.content ==
               """
               a = 1;
               b = 2;
               c = 3;
               d = 4;
               e = 6;
               f = 7;
               """
               |> String.trim()
    end
  end
end
