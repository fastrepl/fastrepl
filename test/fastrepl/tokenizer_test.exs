defmodule Fastrepl.TokenizerTest do
  use ExUnit.Case, async: true
  alias Fastrepl.Tokenizer

  describe "count_tokens/2" do
    test "llama" do
      tok = Tokenizer.load(:llama)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 3
    end
  end

  describe "truncate/3" do
    test "positive" do
      tok = Tokenizer.load(:llama)

      result =
        "I apologize for the confusion. Let's take a closer look at the updated truncate function and fix the issue."
        |> Tokenizer.truncate(tok, 5)

      assert result == "and fix the issue."

      num = result |> Tokenizer.count_tokens(tok)
      assert num == 5 + 1
    end

    test "negative" do
      tok = Tokenizer.load(:llama)

      num = "Hello world" |> Tokenizer.truncate(tok, -1)
      assert num == ""
    end
  end
end
