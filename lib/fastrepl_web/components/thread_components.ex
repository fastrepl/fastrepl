defmodule FastreplWeb.ThreadComponents do
  use Phoenix.Component

  import FastreplWeb.CoreComponents, only: [icon: 1]

  alias Phoenix.LiveView.JS
  alias FastreplWeb.Utils.SharedTask

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
          navigate={"/demo/thread/#{@id}"}
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

  attr :task, SharedTask, required: true

  def task(assigns) do
    ~H"""
    <div
      id={@task.id}
      class="hidden max-w-[350px] truncate rounded-md"
      phx-mounted={
        JS.show(
          transition: {
            "cubic-bezier(0.4, 0, 0.2, 1) duration-500",
            "opacity-0 translate-y-10",
            "opacity-100 translate-y-0"
          },
          time: 500
        )
      }
    >
      <%= cond do %>
        <% @task.async_result.loading -> %>
          <span class="bg-gray-200 px-2 py-1 rounded-md pulse">
            <%= @task.name %>
          </span>
        <% @task.async_result.ok? -> %>
          <span class="bg-green-100 px-2 py-1 rounded-md">
            <%= @task.name %>
          </span>
        <% true -> %>
          <span class="bg-red-100 px-2 py-1 rounded-md">
            <%= @task.name %>
          </span>
      <% end %>
    </div>
    """
  end

  attr :tasks, :list, required: true

  def tasks(assigns) do
    ~H"""
    <div class="flex flex-col gap-4 text-xs w-fit max-h-[100px]">
      <%= for task <- @tasks do %>
        <.task task={task} />
      <% end %>
    </div>
    """
  end

  attr :steps, :list, required: true
  attr :current_step, :string, required: true
  attr :phx_click, :string, required: true

  def horizontal_progress_bar(assigns) do
    ~H"""
    <div class="relative after:absolute after:inset-x-0 after:top-1/2 after:block after:h-0.5 after:-translate-y-1/2 after:rounded-lg after:bg-gray-100">
      <ol class="relative z-10 flex justify-between text-sm font-medium text-gray-500">
        <%= for {step, index} <- Enum.with_index(@steps, 0) do %>
          <li
            class="flex items-center gap-2 bg-white p-2 group"
            phx-click={@phx_click}
            phx-value-step={step}
          >
            <%= if @current_step == step do %>
              <span class="size-6 rounded-full bg-gray-600 text-center text-[10px]/6 font-bold text-white">
                <%= index + 1 %>
              </span>
            <% else %>
              <span class="size-6 rounded-full bg-gray-100 group-hover:bg-gray-600 group-hover:text-white text-center text-[10px]/6 font-bold">
                <%= index + 1 %>
              </span>
            <% end %>
            <span><%= step %></span>
          </li>
        <% end %>
      </ol>
    </div>
    """
  end
end
