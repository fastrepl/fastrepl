defmodule FastreplWeb.Utils do
  def clsx(list) do
    list
    |> Enum.reject(&(&1 == nil))
    |> Enum.reject(&(&1 == false))
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end
end

defmodule FastreplWeb.Utils.SharedTask do
  alias Phoenix.LiveView.AsyncResult

  @type id :: String.t()
  @type name :: String.t()
  @type async_result :: AsyncResult.t()

  defstruct [:id, :name, :async_result]
  @type t :: %__MODULE__{id: id, name: name, async_result: async_result}

  def loading(id, name) do
    %__MODULE__{
      id: id,
      name: name,
      async_result: AsyncResult.loading()
    }
  end

  def ok(%__MODULE__{} = task, data) do
    %__MODULE__{task | async_result: task.async_result |> AsyncResult.ok(data)}
  end
end
