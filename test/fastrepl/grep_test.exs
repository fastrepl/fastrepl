defmodule Fastrepl.GrepTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Native.CodeUtils

  setup do
    path =
      System.tmp_dir!()
      |> Path.join(Nanoid.generate())

    File.write!(path, """
    a = 1
    b = 2
    a = 1
    c = 3
    b = 2
    """)

    on_exit(fn -> File.rm!(path) end)

    %{path: path}
  end

  describe "grep_file/2" do
    test "simple", %{path: path} do
      result = CodeUtils.grep_file(path, "b")
      assert result == [2, 5]
    end
  end
end
