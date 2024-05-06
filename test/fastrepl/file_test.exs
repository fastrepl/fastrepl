defmodule Fastrepl.FileTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Repository

  test "it works" do
    file = %Repository.File{
      path: "test.md",
      content: """
      defmodule Fastrepl.FileTest do
        use ExUnit.Case, async: true

        test "it works" do
          assert 1 + 1 == 2
        end

        test "it works 2" do
          assert 1 + 1 == 2
        end
      end
      """
    }

    assert Repository.File.find_line(file, "hello") == nil
    assert Repository.File.find_line(file, "  defmodule Fastrepl.FileTest") == 1
    assert Repository.File.find_line(file, "assert 1 + 1 == 2\nend\nend") == 9
  end
end
