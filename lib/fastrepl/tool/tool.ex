defmodule Fastrepl.Tool do
  @callback run(dynamic_args :: map(), static_args :: map()) :: any()
  @callback as_function() :: LangChain.Function.t()
end
