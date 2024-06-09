defmodule Fastrepl.PatchTest do
  use ExUnit.Case, async: true

  alias Fastrepl.FS.Patch
  alias Fastrepl.FS.Repository

  describe "from/1" do
    test "indempotent" do
      repo = %Repository{
        original_files: [%{path: "a.py", content: "a"}],
        current_files: [%{path: "a.py", content: "b"}]
      }

      patches = Patch.from(repo)
      assert length(patches) == 1

      patches = Patch.from(repo)
      assert length(patches) == 1
    end

    test "modify" do
      repo = %Repository{
        original_files: [%{path: "a.py", content: "a"}],
        current_files: [%{path: "a.py", content: "b"}]
      }

      [patch] = Patch.from(repo)
      assert patch.status == :modified
      assert patch.path == "a.py"
      assert patch.content |> String.starts_with?("--- a/a.py\n+++ b/a.py\n")
    end

    test "add" do
      repo = %Repository{
        original_files: [],
        current_files: [%{path: "a.py", content: "a"}]
      }

      [patch] = Patch.from(repo)
      assert patch.status == :added
      assert patch.path == "a.py"
      assert patch.content |> String.starts_with?("--- /dev/null\n+++ b/a.py")
    end

    test "remove" do
      repo = %Repository{
        original_files: [%{path: "a.py", content: "a"}],
        current_files: []
      }

      [patch] = Patch.from(repo)
      assert patch.status == :removed
      assert patch.path == "a.py"
      assert patch.content |> String.starts_with?("--- a/a.py\n+++ /dev/null")
    end
  end
end
