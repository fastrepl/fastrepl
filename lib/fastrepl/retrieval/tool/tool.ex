defmodule Fastrepl.Retrieval.Tool do
  @callback run(args :: map(), context :: map()) :: any()
  @callback name() :: String.t()
  @callback schema() :: map()
end
