defmodule Fastrepl.SessionsTest do
  alias Fastrepl.FS.Patch
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Repo
  alias Fastrepl.Sessions
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment

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
    test "session_from/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      ticket_attrs = %{
        github_repo_full_name: "fastrepl/fastrepl",
        github_issue_number: 1
      }

      session_attrs = %{account_id: account.id, display_id: "123"}

      {:ok, ticket} = Sessions.ticket_from(ticket_attrs)
      {:ok, session_1} = Sessions.session_from(ticket, session_attrs)
      {:ok, session_2} = Sessions.session_from(ticket, session_attrs)

      assert session_1.id == session_2.id
      assert session_1.ticket.id == session_2.ticket.id

      assert session_1.comments == []
      assert session_1.patches == []
      assert session_1.ticket.github_repo != nil
      assert session_1.ticket.github_issue != nil

      assert session_2.comments == []
      assert session_2.patches == []
      assert session_2.ticket.github_repo != nil
      assert session_2.ticket.github_issue != nil
    end

    test "session_from/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      ticket_attrs = %{
        github_repo_full_name: "fastrepl/fastrepl",
        github_issue_number: 1
      }

      session_attrs = %{account_id: account.id, display_id: "123"}

      {:ok, ticket} = Sessions.ticket_from(ticket_attrs)
      {:ok, session_1} = Sessions.session_from(ticket, session_attrs)

      session_2 = Sessions.session_from(%{account_id: account.id, display_id: "123"})
      assert session_1.id == session_2.id

      assert session_1.ticket.github_repo != nil
      assert session_1.ticket.github_issue != nil

      assert session_2.ticket.github_repo == nil
      assert session_2.ticket.github_issue == nil

      session_2 = session_2 |> Map.update!(:ticket, &Sessions.enrich_ticket(&1))
      assert session_2.ticket.github_repo != nil
      assert session_2.ticket.github_issue != nil
    end

    test "update_session/2" do
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

      assert session.status == :init

      session = session |> Map.put(:status, :run)
      {:ok, updated_session} = Sessions.update_session(session, %{status: :run})
      assert updated_session.status == :run
    end
  end

  describe "comment" do
    setup do
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

      %{ticket: ticket, session: session}
    end

    test "create_comment/1", %{session: session} do
      valid_comment_attrs = %{
        session_id: session.id,
        file_path: "a.py",
        line_start: 1,
        line_end: 2,
        content: "remove this"
      }

      assert session |> Sessions.list_comments() |> length() == 0

      Sessions.create_comment(%Comment{}, valid_comment_attrs)
      Sessions.create_comment(%Comment{}, valid_comment_attrs |> Map.pop(:session_id) |> elem(1))
      Sessions.create_comment(%Comment{}, valid_comment_attrs |> Map.pop(:content) |> elem(1))

      assert session |> Sessions.list_comments() |> length() == 0 + (3 - 2)
    end

    test "create_comment/2", %{session: session} do
      valid_comment_attrs = %{
        session_id: session.id,
        file_path: "a.py",
        line_start: 1,
        line_end: 2,
        content: "remove this"
      }

      assert session |> Sessions.list_comments() |> length() == 0
      Sessions.create_comment(%Comment{}, valid_comment_attrs)
      Sessions.create_comment(%Comment{}, valid_comment_attrs |> Map.pop(:session_id) |> elem(1))
      Sessions.create_comment(%Comment{}, valid_comment_attrs |> Map.pop(:content) |> elem(1))
      assert session |> Sessions.list_comments() |> length() == 0 + (3 - 2)
    end

    test "delete_comment/1", %{session: session} do
      valid_comment_attrs = %{
        session_id: session.id,
        file_path: "a.py",
        line_start: 1,
        line_end: 2,
        content: "remove this"
      }

      assert session |> Sessions.list_comments() |> length() == 0
      {:ok, %{id: comment_id}} = Sessions.create_comment(%Comment{}, valid_comment_attrs)
      assert session |> Sessions.list_comments() |> length() == 1
      Sessions.delete_comment(%{"id" => comment_id})
      assert session |> Sessions.list_comments() |> length() == 0
    end

    test "update_comment/2", %{session: session} do
      valid_comment_attrs = %{
        session_id: session.id,
        file_path: "a.py",
        line_start: 1,
        line_end: 2,
        content: "original"
      }

      assert session |> Sessions.list_comments() |> length() == 0
      {:ok, comment} = Sessions.create_comment(%Comment{}, valid_comment_attrs)
      assert session |> Sessions.list_comments() |> length() == 1
      Sessions.update_comment(comment, %{content: "updated"})
      assert session |> Sessions.list_comments() |> length() == 1

      assert session
             |> Sessions.list_comments()
             |> get_in([Access.at(0), Access.key(:content)]) == "updated"
    end
  end

  describe "patch" do
    test "create_patch/2" do
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

      {:ok, patch} =
        Sessions.create_patch(%Patch{
          status: :added,
          path: "a.py",
          content: "original",
          session_id: session.id
        })

      assert patch.status == :added
    end
  end
end
