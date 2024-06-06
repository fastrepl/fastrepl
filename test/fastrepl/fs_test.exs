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

    test "respects ignore_patterns" do
      root =
        Application.fetch_env!(:fastrepl, :root)
        |> Path.join("/lib")

      full = FS.list_informative_files(root, [])
      partial = FS.list_informative_files(root, ["**/*.ex"])

      assert length(full) > 0
      assert length(partial) > 0
      assert length(full) - length(partial) > 10
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
    setup do
      path = System.tmp_dir!() |> Path.join(Nanoid.generate())
      content = 1..100 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      File.write!(path, content)

      %{path: path}
    end

    test "simple", %{path: path} do
      assert FS.read_lines!(path, {-2, 2}) == "1\n2\n"
      assert FS.read_lines!(path, {0, 2}) == "1\n2\n"

      assert FS.read_lines!(path, {0, 0}) == ""
      assert FS.read_lines!(path, {0, 1}) == "1\n"
      assert FS.read_lines!(path, {1, 1}) == "1\n"
      assert FS.read_lines!(path, {100, 100}) == "100"
      assert FS.read_lines!(path, {110, 110}) == ""

      assert FS.read_lines!(path, {2, 4}) == "2\n3\n4\n"
      assert FS.read_lines!(path, {42, 46}) == "42\n43\n44\n45\n46\n"

      assert FS.read_lines!(path, {98, 100}) == "98\n99\n100"
      assert FS.read_lines!(path, {98, 110}) == "98\n99\n100"
    end
  end

  describe "search_paths/2" do
    test "simple" do
      root = Application.fetch_env!(:fastrepl, :root) |> Path.join("/lib")

      results =
        root
        |> FS.search_paths("session")
        |> Enum.map(&Path.relative_to(&1, root))

      assert Enum.count(results) > 1
    end
  end

  describe "Repository" do
    test "Mutation.apply/2 list" do
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
            content: "1\n2\n3\n13\n14\n15\n16\n17\n18\n19\n20"
          },
          %FS.File{
            path: "a.py",
            content: "1\n4\n5\n4\n5\n6\n10\n10"
          }
        ]
      }

      assert actual == expected
    end

    test "apply modification in the middle of the file" do
      file = %FS.File{
        path: "a.py",
        content: 1..10 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      }

      repo =
        %FS.Repository{original_files: [file], current_files: [file]}
        |> FS.Mutation.apply(
          FS.Mutation.new(:modify, %{target_path: "a.py", target_section: "2\n3", data: "4\n5"})
        )

      assert repo.original_files == [file]

      assert repo.current_files == [
               %FS.File{
                 path: "a.py",
                 content: "1\n4\n5\n4\n5\n6\n7\n8\n9\n10"
               }
             ]
    end

    test "apply modification in the start of the file" do
      file = %FS.File{
        path: "a.py",
        content: 1..10 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      }

      repo =
        %FS.Repository{original_files: [file], current_files: [file]}
        |> FS.Mutation.apply(
          FS.Mutation.new(:modify, %{target_path: "a.py", target_section: "1\n2", data: "4\n5"})
        )

      assert repo.original_files == [file]

      assert repo.current_files == [
               %FS.File{
                 path: "a.py",
                 content: "4\n5\n3\n4\n5\n6\n7\n8\n9\n10"
               }
             ]
    end

    test "apply modification in the end of the file" do
      file = %FS.File{
        path: "a.py",
        content: 1..10 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      }

      repo =
        %FS.Repository{original_files: [file], current_files: [file]}
        |> FS.Mutation.apply(
          FS.Mutation.new(:modify, %{target_path: "a.py", target_section: "9\n10", data: "4\n5"})
        )

      assert repo.original_files == [file]

      assert repo.current_files == [
               %FS.File{
                 path: "a.py",
                 content: "1\n2\n3\n4\n5\n6\n7\n8\n4\n5"
               }
             ]
    end

    test "apply modification to entire file" do
      file = %FS.File{
        path: "a.py",
        content: 1..4 |> Enum.map(&Integer.to_string/1) |> Enum.join("\n")
      }

      repo =
        %FS.Repository{original_files: [file], current_files: [file]}
        |> FS.Mutation.apply(
          FS.Mutation.new(:modify, %{
            target_path: "a.py",
            target_section: "1\n2\n3\n4",
            data: "4\n5"
          })
        )

      assert repo.original_files == [file]

      assert repo.current_files == [
               %FS.File{
                 path: "a.py",
                 content: "4\n5"
               }
             ]
    end

    test "Repository.apply_patches!/2" do
      tmp = System.tmp_dir!() |> Path.join(Nanoid.generate())
      File.mkdir_p!(tmp)
      File.write!(Path.join(tmp, "a.py"), "1\n2\n3")
      File.write!(Path.join(tmp, "b.py"), "1\n2\n3")
      File.write!(Path.join(tmp, "c.py"), "1\n2\n3")

      checkpoint = %FS.Repository{
        original_files: [
          %FS.File{path: "a.py", content: "1\n2\n3"},
          %FS.File{path: "b.py", content: "1\n2\n3"},
          %FS.File{path: "c.py", content: "1\n2\n3"}
        ],
        current_files: [
          %FS.File{path: "a.py", content: "1\n2\n4"},
          %FS.File{path: "b.py", content: "0\n2\n3"}
        ]
      }

      patches = checkpoint |> FS.Patch.from()
      assert Enum.count(patches) == 3

      restored =
        %FS.Repository{root_path: tmp}
        |> FS.Repository.apply_patches!(patches)
        |> then(fn repo ->
          %FS.Repository{
            original_files: repo.original_files |> Enum.sort_by(& &1.path),
            current_files: repo.current_files |> Enum.sort_by(& &1.path)
          }
        end)

      assert restored == checkpoint
    end
  end
end
