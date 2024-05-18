defmodule Fastrepl.FileTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Repository

  @content "1\n2\n3\n4\n5\n6\n7\n8\n9\n10"

  setup do
    root_path = System.tmp_dir!()
    relative_path = "#{Nanoid.generate()}.py"
    path = Path.join(root_path, relative_path)

    File.write!(path, @content)

    on_exit(fn -> File.rm!(path) end)
    %{root_path: root_path, relative_path: relative_path}
  end

  describe "from/2 (path)" do
    test "valid", %{root_path: root_path, relative_path: relative_path} do
      {:ok, file} = Repository.File.from(%Repository{root_path: root_path}, relative_path)
      assert file.path == relative_path
      assert file.content == @content
    end

    test "invalid", %{root_path: root_path} do
      {:error, changeset} = Repository.File.from(%Repository{root_path: root_path}, "invalid.py")
      assert changeset.errors == [path: {"not exist", []}]
    end
  end

  describe "from/2 (comment)" do
    test "valid", %{root_path: root_path, relative_path: relative_path} do
      {:ok, comment} =
        Repository.Comment.new(%{
          file_path: relative_path,
          content: "hi",
          line_start: 2,
          line_end: 4
        })

      {:ok, file} = Repository.File.from(%Repository{root_path: root_path}, comment)
      assert file.path == relative_path
      assert file.content == @content
    end

    test "invalid", %{root_path: root_path} do
      {:ok, comment} =
        Repository.Comment.new(%{
          file_path: "invalid.py",
          content: "hi",
          line_start: 2,
          line_end: 4
        })

      {:error, changeset} = Repository.File.from(%Repository{root_path: root_path}, comment)
      assert changeset.errors == [path: {"not exist", []}]
    end
  end

  describe "replace/4" do
    test "start" do
      file =
        Repository.File.new!(%{
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
        })

      new_file = file |> Repository.File.replace!(1, 2, ["a = 2;"])

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
      file =
        Repository.File.new!(%{
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
        })

      new_file = file |> Repository.File.replace!(3, 5, ["c = 4;", "d = 5;"])

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
      file =
        Repository.File.new!(%{
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
        })

      new_file = file |> Repository.File.replace!(5, 7, ["e = 6;", "f = 7;"])

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
