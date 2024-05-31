import Ecto.Query
alias Fastrepl.Repo

alias Identity.User
alias Fastrepl.Accounts.Member
alias Fastrepl.Accounts.Account
alias Fastrepl.Billings.Billing

alias Fastrepl.Github
alias Fastrepl.FS.Patch

alias Fastrepl.Sessions
alias Fastrepl.Sessions.Session
alias Fastrepl.Sessions.Ticket
alias Fastrepl.Sessions.Comment

defmodule DEV do
  def list_session() do
    Registry.select(Application.fetch_env!(:fastrepl, :thread_manager_registry), [
      {{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}
    ])
  end

  def list_session(account_id) do
    Registry.select(Application.fetch_env!(:fastrepl, :thread_manager_registry), [
      {{:"$1", :"$2", %{account_id: account_id}}, [], [{{:"$1", :"$2"}}]}
    ])
  end

  def get_session(display_id) do
    {_, pid} =
      list_session()
      |> Enum.find(fn {id, _} -> id == display_id end)

    :sys.get_state(pid)
  end
end
