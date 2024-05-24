defmodule FastreplWeb.MainLive do
  use FastreplWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> redirect(to: "/threads")}
  end
end
