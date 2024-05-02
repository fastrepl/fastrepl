defmodule Fastrepl.ReaderTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Reader

  test "it works" do
    assert Reader.urls_from_text("""
           Hi, we are fastrepl.

           https://fastrepl.com

           Star us on GitHub!
           https://github.com/fastrepl/fastrepl

           Thanks!
           """) == [
             "https://fastrepl.com",
             "https://github.com/fastrepl/fastrepl"
           ]
  end
end
