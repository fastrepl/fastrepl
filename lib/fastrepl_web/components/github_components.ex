defmodule FastreplWeb.GithubComponents do
  use Phoenix.Component
  import FastreplWeb.Utils, only: [clsx: 1]

  attr :full_name, :string, required: true
  attr :description, :string, default: ""
  attr :selected, :boolean, default: false

  def selectable_repo(assigns) do
    ~H"""
    <div
      phx-click="repo:select"
      phx-value-name={@full_name}
      class={
        clsx([
          @selected && "bg-gray-300",
          "flex flex-col items-center gap-2 p-2 border border-black rounded-xl bg-gray-100 hover:bg-gray-200"
        ])
      }
    >
      <.link
        href={"https://github.com/#{@full_name}"}
        class="text-sm font-semibold hover:underline w-fit"
      >
        <%= @full_name %>
      </.link>
      <span class="text-xs max-w-72 truncate"><%= @description %></span>
    </div>
    """
  end

  attr :full_name, :string, required: true
  attr :description, :string, default: ""
  attr :indexing_total, :integer, required: false
  attr :indexing_progress, :integer, required: false

  def repo(assigns) do
    ~H"""
    <div class="flex flex-col items-center gap-2 p-2 border border-black rounded-xl bg-gray-100 relative">
      <.link
        href={"https://github.com/#{@full_name}"}
        class="text-sm font-semibold hover:underline w-fit"
      >
        <%= @full_name %>
      </.link>

      <span class="text-xs truncate max-w-72">
        <%= @description %>
      </span>

      <%= if assigns[:indexing_total] && assigns[:indexing_progress] do %>
        <%= if @indexing_total != @indexing_progress do %>
          <div class="absolute bottom-0.5 w-[calc(100%-2rem)] bg-gray-200 rounded-full h-1.5">
            <div
              class="bg-blue-500 h-1.5 rounded-full"
              style={"width: #{round(@indexing_progress / @indexing_total * 100)}%"}
            />
          </div>
        <% end %>
      <% end %>
    </div>
    """
  end

  attr :repo_full_name, :string, required: true
  attr :title, :string, required: true
  attr :number, :integer, required: true
  attr :selected, :boolean, default: false

  def selectable_issue(assigns) do
    ~H"""
    <div
      phx-click="issue:select"
      phx-value-repo={@repo_full_name}
      phx-value-number={@number}
      class={
        clsx([
          @selected && "bg-gray-300",
          "flex flex-row gap-2 p-2 border border-black rounded-xl bg-gray-100 hover:bg-gray-200 text-sm"
        ])
      }
    >
      <.link
        href={"https://github.com/#{@repo_full_name}/issues/#{@number}"}
        class="text-sm font-semibold hover:underline w-fit"
      >
        #<%= @number %>
      </.link>
      <span class="text-sm max-w-48 truncate">
        <%= @title %>
      </span>
    </div>
    """
  end

  attr :repo_full_name, :string, required: true
  attr :title, :string, required: true
  attr :number, :integer, required: true

  def issue(assigns) do
    ~H"""
    <div class="flex flex-col gap-1 p-2 border border-black rounded-xl bg-gray-100 text-sm">
      <.link
        href={"https://github.com/#{@repo_full_name}/issues/#{@number}"}
        class="text-sm font-semibold hover:underline w-fit px-1"
      >
        #<%= @number %>
      </.link>
      <span class="text-sm truncate max-w-72">
        <%= @title %>
      </span>
    </div>
    """
  end
end
