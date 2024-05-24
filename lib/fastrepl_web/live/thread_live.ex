defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>thread</div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end
end
