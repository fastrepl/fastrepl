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
  # %{
  #   state: :complete | :current | :upcoming,
  #   title: String.t(),
  #   description: String.t()
  # }
  def vertical_progress_bar(assigns) do
    ~H"""
    <nav aria-label="Progress">
      <ol role="list" class="overflow-hidden">
        <%= for {step, index} <- Enum.with_index(@steps) do %>
          <li class={"relative #{if index < length(@steps) - 1, do: "pb-10"}"}>
            <%= if index < length(@steps) - 1 do %>
              <div
                class={"absolute left-4 top-4 -ml-px mt-0.5 h-full w-0.5 #{if step.state == :complete, do: "bg-blue-600", else: "bg-gray-300"}"}
                aria-hidden="true"
              >
              </div>
            <% end %>
            <a
              href="#"
              class={"group relative flex items-start #{if step.state == :current, do: "aria-current='step'"}"}
            >
              <span class="flex h-9 items-center">
                <span class={"relative z-10 flex h-8 w-8 items-center justify-center rounded-full #{get_step_classes(step)}"}>
                  <%= if step.state == :complete do %>
                    <svg
                      class="h-5 w-5 text-white"
                      viewBox="0 0 20 20"
                      fill="currentColor"
                      aria-hidden="true"
                    >
                      <path
                        fill-rule="evenodd"
                        d="M16.704 4.153a.75.75 0 01.143 1.052l-8 10.5a.75.75 0 01-1.127.075l-4.5-4.5a.75.75 0 011.06-1.06l3.894 3.893 7.48-9.817a.75.75 0 011.05-.143z"
                        clip-rule="evenodd"
                      />
                    </svg>
                  <% else %>
                    <span class={"h-2.5 w-2.5 rounded-full #{if step.state == :current, do: "bg-blue-600", else: "bg-transparent group-hover:bg-gray-300"}"}>
                    </span>
                  <% end %>
                </span>
              </span>
              <span class="ml-4 flex min-w-0 flex-col">
                <span class={"text-sm font-medium #{if step.state == :current, do: "text-blue-600", else: "text-gray-500"}"}>
                  <%= step.title %>
                </span>
                <span class="text-sm text-gray-500">
                  <%= step.description %>
                </span>
              </span>
            </a>
          </li>
        <% end %>
      </ol>
    </nav>
    """
  end

  defp get_step_classes(step) do
    case step.state do
      :complete -> "bg-blue-600 group-hover:bg-blue-800"
      :current -> "border-2 border-blue-600 bg-white"
      :upcoming -> "border-2 border-gray-300 bg-white group-hover:border-gray-400"
    end
  end
end
