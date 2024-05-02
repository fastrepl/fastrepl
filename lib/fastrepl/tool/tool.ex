defmodule Fastrepl.Tool do
  @callback run(dynamic_args :: map(), static_args :: map()) :: any()
  @callback openai_tool_format() :: map()
end
