defmodule FastreplWeb.ThreadsDemoLive do
  use FastreplWeb, :live_view
  import FastreplWeb.GithubComponents, only: [repo: 1, issue: 1]

  alias Phoenix.LiveView.AsyncResult
  alias Fastrepl.Orchestrator
  alias Fastrepl.Github

  @repos [
    {
      "BerriAI/litellm",
      "Call all LLM APIs using the OpenAI format. Use Bedrock, Azure, OpenAI, Cohere, Anthropic, Ollama, Sagemaker, HuggingFace, Replicate (100+ LLMs)"
    },
    {
      "explodinggradients/ragas",
      "Evaluation framework for your Retrieval Augmented Generation (RAG) pipelines"
    },
    {
      "honojs/hono",
      "Web Framework built on Web Standards"
    },
    {
      "brainlid/langchain",
      "Elixir implementation of a LangChain style framework."
    }
  ]

  def render(assigns) do
    ~H"""
    <h2 class="text-lg font-semibold">
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

    <div class="mt-4 grid grid-cols-2 grid-rows-2 gap-4">
      <%= for {name, description} <- @repos do %>
        <.repo full_name={name} selected={name == @selected_repo} description={description} />
      <% end %>
    </div>

    <%= if @selected_repo do %>
      <h2 class="text-lg font-semibold mt-12">
        Github Issues
      </h2>

      <%= if @async_result_issues.loading do %>
        <div class="mt-4 grid grid-cols-3 gap-4">
          <%= for _ <- 1..9 do %>
            <.issue repo_full_name={@selected_repo} title="..." number={0} />
          <% end %>
        </div>
      <% else %>
        <div class="mt-4 grid grid-cols-3 gap-4">
          <%= for issue <- @async_result_issues.result do %>
            <.issue
              repo_full_name={@selected_repo}
              title={issue.title}
              number={issue.number}
              selected={issue.number == @selected_issue}
            />
          <% end %>
        </div>
      <% end %>
    <% end %>

    <%= if @selected_repo && @selected_issue do %>
      <.button phx-click="submit" class="w-full text-lg mt-8">
        Start thread
      </.button>
    <% end %>
    """
  end

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:repos, @repos)
      |> assign(:selected_repo, nil)
      |> assign(:selected_issue, nil)

    {:ok, socket}
  end

  def handle_event("submit", _params, socket) do
    thread_id = Nanoid.generate()

    {:ok, _} =
      Orchestrator.start(%{
        thread_id: thread_id,
        repo_full_name: socket.assigns.selected_repo,
        issue_number: @selected_issue
      })

    {:noreply, socket |> redirect(to: "/demo/thread/#{thread_id}")}
  end

  def handle_event("repo:select", %{"name" => name}, socket) do
    socket =
      socket
      |> assign(:selected_repo, name)
      |> assign(:selected_issue, nil)
      |> start_fetching_issues(name)

    {:noreply, socket}
  end

  def handle_event("issue:select", %{"number" => number}, socket) do
    {:noreply, socket |> assign(:selected_issue, number |> String.to_integer())}
  end

  def handle_async(:fetch_issues, {:ok, issues}, socket) do
    {:noreply, socket |> assign(:async_result_issues, AsyncResult.ok(%AsyncResult{}, issues))}
  end

  def handle_async(:fetch_issues, {:exit, reason}, socket) do
    {:noreply, socket |> assign(:async_result_issues, AsyncResult.failed(%AsyncResult{}, reason))}
  end

  defp start_fetching_issues(socket, repo_full_name) do
    socket
    |> assign(:async_result_issues, AsyncResult.loading())
    |> start_async(:fetch_issues, fn ->
      Github.list_open_issues!(repo_full_name)
      |> Enum.reject(fn issue -> issue.pull_request != nil end)
      |> Enum.take(9)
    end)
  end
end
