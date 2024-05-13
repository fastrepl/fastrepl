defmodule FastreplWeb.DevUrlLive do
  use FastreplWeb, :live_view
  alias Fastrepl.Renderer
  alias Fastrepl.Github

  def render(assigns) do
    ~H"""
    <div class="flex flex-col">
      <div class="flex flex-row justify-between">
        <.form for={@form} phx-submit="submit" class="flex flex-row gap-1 items-center ">
          <.input type="url" field={@form[:url]} class="w-92" />
          <.button type="text" class="mt-2">Get Text</.button>
        </.form>
        <.link target="_blank" href={@issue_url} class="text-blue-500 underline">
          Submit Github Issue
        </.link>
      </div>
      <pre class={[
        "w-full mt-8 p-2 bg-gray-50 rounded-xl",
        "h-[calc(100vh-200px)] overflow-y-hidden hover:overflow-y-auto"
      ]}><%= @text %></pre>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       form: to_form(%{"url" => ""}),
       text: "",
       issue_url:
         Github.URL.create_issue("fastrepl/fastrepl",
           title: "Fastrepl.Renderer.URL.render/1",
           labels: "enhancement"
         )
     )}
  end

  def handle_params(params, _url, socket) do
    if params["url"] do
      text = Renderer.URL.render(params["url"])

      issue_url =
        Github.URL.create_issue("fastrepl/fastrepl",
          title: "Renderer.URL.render/1 with '#{params["url"]}'",
          body: """
          I tried `Renderer.URL.render/1` with `#{params["url"]}`.

          I expect it to return [TODO],

          but got this:
          ```
          #{text}
          ```
          """,
          labels: "enhancement"
        )

      socket =
        socket
        |> assign(form: to_form(params))
        |> assign(text: text)
        |> assign(issue_url: issue_url)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_event("submit", %{"url" => url}, socket) do
    {:noreply, socket |> push_patch(to: ~p"/dev/url?url=#{url}")}
  end
end
