defmodule FastreplWeb.MainLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>
      <span>Demo:</span>
      <.link href={~p"/demo/new"}>Go</.link>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
