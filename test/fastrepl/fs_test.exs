defmodule Fastrepl.FSTest do
  use ExUnit.Case

  alias Fastrepl.FS

  describe "list_informative_files/1" do
    test "returns absolute paths" do
      root =
        Application.fetch_env!(:fastrepl, :root)
        |> Path.join("/lib")

      paths = FS.list_informative_files(root)

      assert paths |> length() > 10
      assert Enum.all?(paths, &String.starts_with?(&1, root))
    end
  end

  describe "Tree.build/1" do
    test "flat" do
      paths = ["a.py", "b.py", "c.py"]

      assert FS.Tree.build(paths) == [
               %FS.Tree{name: "a.py", path: "a.py"},
               %FS.Tree{name: "b.py", path: "b.py"},
               %FS.Tree{name: "c.py", path: "c.py"}
             ]
    end

    test "recursive" do
      paths = ["src/a.py", "src/b.py", "src/c/d.py"]

      assert FS.Tree.build(paths) == [
               %FS.Tree{
                 name: "src",
                 path: "src",
                 children: [
                   %FS.Tree{name: "a.py", path: "src/a.py"},
                   %FS.Tree{name: "b.py", path: "src/b.py"},
                   %FS.Tree{
                     name: "c",
                     path: "src/c",
                     children: [
                       %FS.Tree{name: "d.py", path: "src/c/d.py"}
                     ]
                   }
                 ]
               }
             ]
    end

    test "multiple files in a folder" do
      paths = ["src/folder/a.py", "src/folder/b.py", "src/folder/c/d.py", "src/folder/c/e.py"]

      assert FS.Tree.build(paths) == [
               %FS.Tree{
                 name: "src",
                 path: "src",
                 children: [
                   %FS.Tree{
                     name: "folder",
                     path: "src/folder",
                     children: [
                       %FS.Tree{name: "a.py", path: "src/folder/a.py"},
                       %FS.Tree{name: "b.py", path: "src/folder/b.py"},
                       %FS.Tree{
                         name: "c",
                         path: "src/folder/c",
                         children: [
                           %FS.Tree{name: "d.py", path: "src/folder/c/d.py"},
                           %FS.Tree{name: "e.py", path: "src/folder/c/e.py"}
                         ]
                       }
                     ]
                   }
                 ]
               }
             ]
    end
  end

  describe "Tree.render/1" do
    paths = ["src/folder/a.py", "src/folder/b.py", "src/folder/c/d.py", "src/folder/c/e.py"]
    actual = paths |> FS.Tree.build() |> FS.Tree.render()

    expected = """
    src
      folder
        a.py
        b.py
        c
          d.py
          e.py
    """

    assert actual == expected
  end

  describe "read_lines!/2" do
    test "simple" do
      path = System.tmp_dir!() |> Path.join(Nanoid.generate())
      File.write!(path, 1..100 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n"))

      assert FS.read_lines!(path, {42, 46}) == "42\n43\n44\n45\n46\n"
    end
  end

  describe "search_paths/2" do
    test "simple" do
      root = Application.fetch_env!(:fastrepl, :root) |> Path.join("/lib")

      count =
        root
        |> FS.search_paths("thread")
        |> Enum.map(&Path.relative_to(&1, root))
        |> Enum.count()

      assert count > 3
    end
  end

  describe "Repository" do
    test "it works" do
      file = %FS.File{
        path: "a.py",
        content: 1..10 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      }

      repo = %FS.Repository{original_files: [file], current_files: [file]}

      ops = [
        FS.Mutation.new(
          :add,
          %{
            target_path: "b.py",
            data: 11..20 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
          }
        ),
        FS.Mutation.new(
          :modify,
          %{
            target_path: "a.py",
            target_section: "2\n3",
            data: "4\n5"
          }
        ),
        FS.Mutation.new(
          :modify,
          %{
            target_path: "a.py",
            target_section: "7\n8\n9",
            data: "10"
          }
        ),
        FS.Mutation.new(
          :modify,
          %{
            target_path: "b.py",
            target_section: "11\n12",
            data: "1\n2\n3"
          }
        )
      ]

      actual = ops |> Enum.reduce(repo, &FS.Mutation.apply(&2, &1))

      expected = %FS.Repository{
        original_files: [
          %FS.File{
            path: "a.py",
            content: "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"
          }
        ],
        current_files: [
          %FS.File{
            path: "b.py",
            content: "\n1\n2\n3\n13\n14\n15\n16\n17\n18\n19\n20"
          },
          %FS.File{
            path: "a.py",
            content: "1\n4\n5\n4\n5\n6\n10\n10"
          }
        ]
      }

      assert actual == expected
    end
  end
end
