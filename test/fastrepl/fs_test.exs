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
end
