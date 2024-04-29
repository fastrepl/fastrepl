defmodule FastreplWeb.ThreadsDemoLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Orchestrator

  @demo_repo_full_name "brainlid/langchain"

  def render(assigns) do
    ~H"""
    <h2 id="threads" class="text-lg font-semibold">
      Fastrepl Demo
    </h2>
    <p class="mt-2">
      This page is for anyone who wants to try out
      <span class="font-semibold">
        without logging in.
      </span>
    </p>
    <p class="mt-2">
      <span class="font-semibold">
        There are two limitations:
      </span>
      <ul class="list-disc pl-6 mt-1">
        <li>You can only use it for specific set of public repositories.</li>
        <li>
          Each thread has a unique url, and it's public while active. <br />
          It will be terminated after you close the tab.
        </li>
      </ul>
    </p>

    <br />
    <p class="mt-4 mb-10 underline text-lg">
      ↓ Select a repo below to start a thread:
    </p>

    <h2 class="text-lg font-semibold">
      Github Repos
    </h2>

    <button phx-click="submit" class="mt-4 underline text-lg">
      Go
    </button>
    """
  end

  def mount(_params, _session, socket) do
    threads =
      Registry.select(Application.fetch_env!(:fastrepl, :orchestrator_registry), [
        {{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}
      ])

    socket =
      socket |> assign(:threads, threads)

    {:ok, socket}
  end

  def handle_event("submit", _params, socket) do
    thread_id = Nanoid.generate()

    {:ok, _} =
      Orchestrator.start(%{
        thread_id: thread_id,
        repo_full_name: @demo_repo_full_name
      })

    {:noreply, socket |> redirect(to: "/demo/thread/#{thread_id}")}
  end
end
