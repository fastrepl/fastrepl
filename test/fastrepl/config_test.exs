defmodule Fastrepl.ConfigTest do
  alias Fastrepl.Config

  use ExUnit.Case, async: true

  describe "parse/1" do
    test "valid" do
      config = """
      ---
      version: 1
      """

      {:ok, config} = Config.parse(config)

      assert config == %Config{
               version: 1,
               base_branch: nil,
               ignored_paths: []
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
