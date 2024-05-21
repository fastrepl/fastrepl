defmodule Fastrepl.TokenizerTest do
  use ExUnit.Case, async: true
  alias Fastrepl.Tokenizer

  describe "count_tokens/2" do
    test "empty" do
      tok = Tokenizer.load!(:gpt_4)

      num = "" |> Tokenizer.count_tokens(tok)
      assert num == 0
    end

    test "llama_2" do
      tok = Tokenizer.load!(:llama_2)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 3
    end

    test "llama_3" do
      tok = Tokenizer.load!(:llama_3)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 3
    end

    test "gpt_3_5" do
      tok = Tokenizer.load!(:gpt_3_5)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 2
    end

    test "gpt_4" do
      tok = Tokenizer.load!(:gpt_4)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 2
    end

    test "claude" do
      tok = Tokenizer.load!(:claude)

      num = "Hello world" |> Tokenizer.count_tokens(tok)
      assert num == 2
    end
  end

  describe "truncate/3" do
    test "positive" do
      tok = Tokenizer.load!(:gpt_3_5)

      result =
        "I apologize for the confusion. Let's take a closer look at the updated truncate function and fix the issue."
        |> Tokenizer.truncate(tok, 5)

      assert result == "and fix the issue."

      num = result |> Tokenizer.count_tokens(tok)
      assert num == 5
    end

    test "negative" do
      tok = Tokenizer.load!(:gpt_3_5)

      num = "Hello world" |> Tokenizer.truncate(tok, -1)
      assert num == ""
    end
  end
end
