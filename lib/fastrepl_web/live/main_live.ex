defmodule FastreplWeb.MainLive do
  use FastreplWeb, :live_view
  import FastreplWeb.AuthComponents, only: [sign_in_with_github: 1]

  def render(assigns) do
    ~H"""
    <div>
      <span>Demo:</span>
      <.link href={~p"/demo/new"}>Go</.link>
      <.sign_in_with_github />
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
