defmodule FastreplWeb.SessionComponents do
  use Phoenix.Component

  attr :name, :string
  attr :title, :string
  attr :number, :string

  def github_issue(assigns) do
    ~H"""
    <div class="flex flex-row gap-2 py-1 px-2 border border-black rounded-lg bg-gray-100 text-sm w-fit max-w-[300px]">
      <a
        href="https://github.com/{repoFullName}/issues/{issueNumber}"
        class="text-sm font-semibold hover:underline px-1"
      >
        <%= "#" <> to_string(@number) %>
      </a>
      <span class="text-sm truncate max-w-72">
        <%= @title %>
      </span>
    </div>
    """
  end

  attr :name, :string
  attr :sha, :string
  attr :description, :string

  def github_repo(assigns) do
    ~H"""
    <div class={[
      "flex flex-col items-center gap-2 p-2 w-fit max-w-[300px]",
      "border border-black rounded-lg bg-gray-100"
    ]}>
      <div class="flex flex-row items-center truncate">
        <a href={"https://github.com/#{@name}"} class="text-sm font-semibold hover:underline w-fit">
          <%= @name %>
        </a>

        <a
          href={"https://github.com/#{@name}/tree/#{@sha}"}
          class="text-xs hover:underline ml-1 border border-gray-300 rounded-md px-1 py-0.5 text-gray-700"
        >
          <%= String.slice(@sha, 0, 7) %>
        </a>
      </div>

      <span :if={@description} class="text-xs truncate">
        <%= @description %>
      </span>
    </div>
    """
  end
end
