defmodule Fastrepl.ConfigTest do
  alias Fastrepl.Config

  use ExUnit.Case, async: true

  describe "parse/1" do
    test "valid" do
      config = """
      ---
      version: 1
      base_branch: main
      ignored_paths:
        - "**/*.py"
      """

      {:ok, config} = Config.parse(config)

      assert config == %Config{
               version: 1,
               base_branch: "main",
               ignored_paths: ["**/*.py"]
             }
    end

    test "invalid" do
      config = """
      ---
      a
      """

      {:error, _} = Config.parse(config)

      config = """
      ---
      version: 1
      base_branch: 1
      """

      {:error, _} = Config.parse(config)
    end
  end
end
