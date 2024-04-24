defmodule Fastrepl.NativeTest do
  use ExUnit.Case, async: true

  test "it works" do
    assert Fastrepl.Native.RustChunker.add(1, 2) == 3
  end
end
