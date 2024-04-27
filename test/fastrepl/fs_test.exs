defmodule Fastrepl.FSTest do
  use ExUnit.Case

  alias Fastrepl.FS

  describe "list_informative_files/1" do
    test "simple" do
      root = System.tmp_dir!() |> Path.join("langchainjs")
      FS.git_clone("https://github.com/langchain-ai/langchainjs.git", root)

      assert FS.list_informative_files(root) |> length() > 3000

      File.rm_rf!(root)
    end
  end

  describe "build_tree/1" do
    test "flat" do
      paths = ["a.py", "b.py", "c.py"]

      assert FS.build_tree(paths) == [
               %{name: "a.py", path: "a.py"},
               %{name: "b.py", path: "b.py"},
               %{name: "c.py", path: "c.py"}
             ]
    end

    test "recursive" do
      paths = ["src/a.py", "src/b.py", "src/c/d.py"]

      assert FS.build_tree(paths) == [
               %{
                 name: "src",
                 path: "src",
                 children: [
                   %{name: "a.py", path: "src/a.py"},
                   %{name: "b.py", path: "src/b.py"},
                   %{
                     name: "c",
                     path: "src/c",
                     children: [
                       %{name: "d.py", path: "src/c/d.py"}
                     ]
                   }
                 ]
               }
             ]
    end
  end
end
