defmodule Fastrepl.URLTest do
  use ExUnit.Case, async: true

  alias Fastrepl.URL

  describe "from/1" do
    test "it works" do
      assert URL.from("""
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
end
