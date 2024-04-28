defmodule FastreplWeb.ThreadComponents do
  use Phoenix.Component

  import FastreplWeb.CoreComponents, only: [icon: 1]
  alias Fastrepl.Retrieval.Chunker.Chunk

  attr :id, :string, required: true
  attr :repo_full_name, :string, required: true
  attr :description, :string, required: true
  attr :delete_event_name, :string, required: true

  def thread(assigns) do
    ~H"""
    <div class="flex items-center gap-2 border rounded-md shadow-md justify-between text-sm relative">
      <div class="flex items-center gap-2">
        <.link
          href={"https://github.com/#{@repo_full_name}"}
          class="hover:font-semibold overflow-hidden overflow-ellipsis whitespace-nowrap w-fit border p-0.5 m-0.5 rounded-md bg-gray-100"
        >
          <%= @repo_full_name %>
        </.link>

        <.link
          navigate={"/demo/#{@id}"}
          class="hover:font-semibold overflow-hidden overflow-ellipsis whitespace-nowrap max-w-[330px]"
        >
          <%= @description %>
        </.link>
      </div>

      <div class="cursor-pointer mx-2" phx-click={@delete_event_name} phx-value-id={@id}>
        <.icon name="hero-x-mark" class="h-4 w-4 text-gray-500 hover:text-black" />
      </div>
    </div>
    """
  end

  attr :chunk, Chunk, required: true
  attr :highlight_lines, :list, default: []

  def render_chunk(assigns) do
    ~H"""
    <pre class="h-[calc(100vh-300px)] rounded-lg bg-[#0d1117]"><code
        id={:crypto.hash(:sha, to_string(@chunk)) |> Base.encode16(case: :lower)}
        phx-hook="Highlight" highlight-lines={Jason.encode!(@highlight_lines)}
        class="h-[calc(100vh-300px)] rounded-lg text-xs"
      ><%= @chunk.content %></code>
    </pre>
    """
  end
end
