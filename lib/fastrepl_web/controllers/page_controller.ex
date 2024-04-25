defmodule FastreplWeb.PageController do
  use FastreplWeb, :controller

  def new_demo(conn, _params) do
    id = Nanoid.generate()
    conn |> redirect(to: "/demo/#{id}")
  end
end
