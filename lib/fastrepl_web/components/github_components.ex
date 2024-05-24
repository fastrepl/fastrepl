defmodule FastreplWeb.GithubComponents do
  use Phoenix.Component
  import FastreplWeb.Utils, only: [clsx: 1]

  attr :repo_full_name, :string

  def repo_list_item(assigns) do
    ~H"""
    <div class="flex items-center gap-2 border rounded-md shadow-md justify-between text-sm relative">
      <div class="flex items-center gap-2">
        <img
          src={"//ui-avatars.com/api/?name=#{@repo_full_name}&background=f0e9e9&font-size=0.35"}
          class="h-8 w-8 rounded flex-shrink-0"
        />
        <.link
          target="_blank"
          href={"https://github.com/#{@repo_full_name}"}
          class="hover:font-semibold"
        >
          <%= @repo_full_name %>
        </.link>
      </div>
    </div>
    """
  end

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
end
