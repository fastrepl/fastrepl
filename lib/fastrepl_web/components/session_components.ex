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

  attr :status, :string
  attr :display_id, :string
  attr :github_issue_number, :integer
  attr :github_repo_full_name, :string

  def session_list_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2 border rounded-md shadow-md text-sm">
      <img
        src={"//ui-avatars.com/api/?name=#{@github_repo_full_name}&background=f0e9e9&font-size=0.35"}
        class="h-8 w-8 rounded flex-shrink-0"
      />
      <div class="flex items-center w-full">
        <.link
          href={"https://github.com/#{@github_repo_full_name}/issues/#{@github_issue_number}"}
          class="hover:font-semibold"
        >
          <%= "#{@github_repo_full_name} ##{@github_issue_number}" %>
        </.link>
        <.link navigate={"/session/#{@display_id}"} class="ml-auto mr-2">
          <span class="text-xs text-gray-400"><%= @status %></span>
          <span class="hero-arrow-right-solid w-4 h-4 text-gray-600 hover:text-black" />
        </.link>
      </div>
    </div>
    """
  end
end
