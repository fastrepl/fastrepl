defmodule Fastrepl.FSTest do
  use ExUnit.Case

  alias Fastrepl.FS

  describe "list_informative_files/1" do
    test "it works" do
      assert Application.fetch_env!(:fastrepl, :root)
             |> Path.join("/lib")
             |> FS.list_informative_files()
             |> length() > 10
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

    test "multiple files in a folder" do
      paths = ["src/folder/a.py", "src/folder/b.py", "src/folder/c/d.py", "src/folder/c/e.py"]

      assert FS.build_tree(paths) == [
               %{
                 name: "src",
                 path: "src",
                 children: [
                   %{
                     name: "folder",
                     path: "src/folder",
                     children: [
                       %{name: "a.py", path: "src/folder/a.py"},
                       %{name: "b.py", path: "src/folder/b.py"},
                       %{
                         name: "c",
                         path: "src/folder/c",
                         children: [
                           %{name: "d.py", path: "src/folder/c/d.py"},
                           %{name: "e.py", path: "src/folder/c/e.py"}
                         ]
                       }
                     ]
                   }
                 ]
               }
             ]
    end
  end

  describe "read_lines/2" do
    test "simple" do
      path = System.tmp_dir!() |> Path.join(Nanoid.generate())
      File.write!(path, 1..100 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n"))

      assert FS.read_lines(path, {42, 46}) == Enum.join(["42\n", "43\n", "44\n", "45\n", "46\n"])
    end
  end

  describe "search_paths/2" do
    test "simple" do
      root = Application.fetch_env!(:fastrepl, :root) |> Path.join("/lib")

      actual =
        root
        |> FS.search_paths("thread")
        |> Enum.map(&Path.relative_to(&1, root))

      expected = [
        "fastrepl_web/live/threads_demo_live.ex",
        "fastrepl_web/live/thread_live.ex",
        "fastrepl_web/live/threads_live.ex",
        "fastrepl_web/components/thread_components.ex",
        "fastrepl_web/live/thread_debug_live.ex"
      ]

      assert Enum.sort(actual) == Enum.sort(expected)
    end
  end
end
