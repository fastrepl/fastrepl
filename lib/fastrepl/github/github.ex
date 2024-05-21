defmodule Fastrepl.Github do
  @moduledoc """
  https://hexdocs.pm/oapi_github
  """

  def get_installation_token!(installation_id) do
    {:ok, %{token: token}} =
      GitHub.Apps.create_installation_access_token(
        installation_id,
        %{},
        auth: GitHub.app(:fastrepl)
      )

    token
  end
end
