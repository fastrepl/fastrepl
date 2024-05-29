defmodule Fastrepl.SessionsTest do
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Repo
  alias Fastrepl.Sessions
  alias Fastrepl.Sessions.Ticket

  describe "ticket" do
    test "it works" do
      attrs = %{
        github_repo_full_name: "fastrepl/fastrepl",
        github_issue_number: 1
      }

      assert Ticket |> Repo.all() |> length() == 0
      {:ok, ticket_1} = Sessions.ticket_from(attrs)
      assert Ticket |> Repo.all() |> length() == 1
      {:ok, ticket_2} = Sessions.ticket_from(attrs)
      assert Ticket |> Repo.all() |> length() == 1
      assert ticket_1.id == ticket_2.id

      assert ticket_1.github_repo != nil
      assert ticket_1.github_issue != nil

      assert ticket_2.github_repo != nil
      assert ticket_2.github_issue != nil
    end
  end

  describe "session" do
    test "preloaded comments and patches" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      ticket_attrs = %{
        github_repo_full_name: "fastrepl/fastrepl",
        github_issue_number: 1
      }

      session_attrs = %{account_id: account.id, display_id: "123"}

      {:ok, ticket} = Sessions.ticket_from(ticket_attrs)
      {:ok, session_1} = Sessions.session_from(ticket, session_attrs)
      {:ok, session_2} = Sessions.session_from(ticket, session_attrs)

      assert session_1.comments == []
      assert session_1.patches == []
      assert session_2.comments == []
      assert session_2.patches == []
    end

    test "it works" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      ticket_attrs = %{
        github_repo_full_name: "fastrepl/fastrepl",
        github_issue_number: 1
      }

      {:ok, ticket_1} = Sessions.ticket_from(ticket_attrs)
      assert ticket_1.session_id == nil
      assert ticket_1.github_repo != nil
      assert ticket_1.github_issue != nil

      session_attrs = %{account_id: account.id, display_id: "123"}

      assert account |> Sessions.list_sessions() |> length() == 0
      {:ok, session} = Sessions.session_from(ticket_1, session_attrs)
      assert account |> Sessions.list_sessions() |> length() == 1

      {:ok, ticket_2} = Sessions.ticket_from(ticket_attrs)
      assert ticket_1.id == ticket_2.id
      assert ticket_2.session_id != nil

      assert session.ticket.id == ticket_1.id
      assert session.ticket.github_repo != nil
      assert session.ticket.github_issue != nil
    end
  end

  describe "comment" do
    test "it works" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      {:ok, ticket} =
        Sessions.ticket_from(%{
          github_repo_full_name: "fastrepl/fastrepl",
          github_issue_number: 1
        })

      {:ok, session} =
        Sessions.session_from(
          ticket,
          %{account_id: account.id, display_id: "123"}
        )

      valid_comment_attrs = %{
        session_id: session.id,
        file_path: "a.py",
        line_start: 1,
        line_end: 2,
        content: "remove this"
      }

      assert session |> Sessions.list_comments() |> length() == 0

      Sessions.create_comment(valid_comment_attrs)
      Sessions.create_comment(valid_comment_attrs |> Map.pop(:session_id) |> elem(1))
      Sessions.create_comment(valid_comment_attrs |> Map.pop(:content) |> elem(1))

      assert session |> Sessions.list_comments() |> length() == 0 + (3 - 2)
    end
  end
end
