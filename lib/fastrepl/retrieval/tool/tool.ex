defmodule Fastrepl.Retrieval.Tool do
  @callback run(args :: map(), context :: map()) :: any()
  @callback as_function() :: LangChain.Function.t()
end
