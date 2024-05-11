defmodule Fastrepl.RepositoryTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Repository

  describe "single mutation" do
    test "edit" do
      files = [Repository.File.new!(%{path: "a.py", content: "a"})]
      repo = Repository.new!(%{original_files: files, current_files: files})
      op = Repository.Mutation.new_edit!(%{file_path: "a.py", target: "a", content: "b"})

      repo = Repository.Mutation.run!(repo, op)
      assert length(repo.current_files) == 1

      diffs = Repository.Diff.from(repo)
      assert length(diffs) == 1

      assert diffs |> Enum.map(&Repository.Diff.to_patch/1) == [
               """
               --- a/a.py
               +++ b/a.py
               @@ -1 +1 @@
               -a
               \\ No newline at end of file
               +b
               \\ No newline at end of file
               """
             ]
    end

    test "create" do
      files = [Repository.File.new!(%{path: "a.py", content: "a"})]
      repo = Repository.new!(%{original_files: files, current_files: files})
      ops = [Repository.Mutation.new_create!(%{file_path: "b.py", content: "b"})]

      repo = ops |> Enum.reduce(repo, &Repository.Mutation.run!(&2, &1))
      assert length(repo.current_files) == 1 + 1

      diffs = Repository.Diff.from(repo)
      assert length(diffs) == 1

      assert diffs |> Enum.map(&Repository.Diff.to_patch/1) == [
               """
               --- /dev/null
               +++ b/b.py
               @@ -0,0 +1 @@
               +b
               \\ No newline at end of file
               """
             ]
    end

    test "delete" do
      files = [Repository.File.new!(%{path: "a.py", content: "a"})]
      repo = Repository.new!(%{original_files: files, current_files: files})
      ops = [Repository.Mutation.new_delete!(%{file_path: "a.py"})]

      repo = ops |> Enum.reduce(repo, &Repository.Mutation.run!(&2, &1))
      diffs = Repository.Diff.from(repo)

      assert length(repo.current_files) == 0
      assert length(diffs) == 1
    end
  end

  describe "multiple mutation" do
    test "editing same file" do
      files = [Repository.File.new!(%{path: "a.py", content: "a"})]
      repo = Repository.new!(%{original_files: files, current_files: files})

      ops = [
        Repository.Mutation.new_edit!(%{file_path: "a.py", target: "a", content: "b\nc"}),
        Repository.Mutation.new_edit!(%{file_path: "a.py", target: "c", content: "d\ne"})
      ]

      repo = ops |> Enum.reduce(repo, &Repository.Mutation.run!(&2, &1))
      assert length(repo.current_files) == 1

      diffs = Repository.Diff.from(repo)
      assert length(diffs) == 1

      assert diffs |> Enum.map(&Repository.Diff.to_patch/1) == [
               """
               --- a/a.py
               +++ b/a.py
               @@ -1 +1,3 @@
               -a
               \\ No newline at end of file
               +b
               +d
               +e
               \\ No newline at end of file
               """
             ]
    end
  end
end
