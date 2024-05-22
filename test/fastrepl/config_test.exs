defmodule Fastrepl.ConfigTest do
  alias Fastrepl.Config

  use ExUnit.Case, async: true

  describe "parse/1" do
    test "it works" do
      config = """
      ---
      version: 1
      issue_delay_seconds: 200
      """

      assert Config.parse!(config) == %Config{version: 1, issue_delay_seconds: 200}
    end
  end
end
