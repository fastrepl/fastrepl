defmodule Fastrepl.Retrieval.Tool do
  @callback run(args :: map(), context :: map()) :: any()
  @callback schema() :: map()
end
