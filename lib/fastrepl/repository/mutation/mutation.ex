defmodule Fastrepl.Repository.Mutation do
  @moduledoc """
  Mutation can modify a single section of a file, create a new file, or delete a file.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Repository

  @type t :: %Mutation{}

  @primary_key false
  embedded_schema do
    field :mode, Ecto.Enum, values: [:edit, :create, :delete]
    field :file_path, :string
    field :target, :string
    field :content, :string
  end

  @spec new_edit(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_edit(attrs \\ %{}) do
    %Mutation{mode: :edit}
    |> cast(attrs, [:file_path, :target, :content])
    |> validate_required([:file_path, :target, :content])
    |> apply_action(:insert)
  end

  @spec new_edit!(attrs :: map()) :: t
  def new_edit!(attrs \\ %{}) do
    {:ok, op} = new_edit(attrs)
    op
  end

  @spec new_create(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_create(attrs \\ %{}) do
    %Mutation{mode: :create}
    |> cast(attrs, [:file_path, :content])
    |> validate_required([:file_path, :content])
    |> apply_action(:insert)
  end

  @spec new_create!(attrs :: map()) :: t
  def new_create!(attrs \\ %{}) do
    {:ok, op} = new_create(attrs)
    op
  end

  @spec new_delete(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_delete(attrs \\ %{}) do
    %Mutation{mode: :delete}
    |> cast(attrs, [:file_path])
    |> validate_required([:file_path])
    |> apply_action(:insert)
  end

  @spec new_delete!(attrs :: map()) :: t
  def new_delete!(attrs \\ %{}) do
    {:ok, op} = new_delete(attrs)
    op
  end

  @spec run(Repository.t(), Mutation.t()) ::
          {:ok, Repository.t()} | {:error, Ecto.Changeset.t()}
  def run(%Repository{} = repo, %Mutation{mode: :edit} = op) do
    file_index = repo.current_files |> Enum.find_index(&(&1.path == op.file_path))

    if file_index == nil do
      repo
      |> change()
      |> add_error(:file_path, "not exist")
    else
      old_file = repo.current_files |> Enum.at(file_index)
      {line_start, line_end} = Fastrepl.String.find_code_block(op.target, old_file.content)

      case Repository.File.replace(old_file, line_start, line_end, String.split(op.content, "\n")) do
        {:ok, new_file} ->
          Repository.replace_file(repo, new_file)

        {:error, changeset} ->
          {:error, changeset}
      end
    end
  end

  def run(%Repository{} = repo, %Mutation{mode: :create} = op) do
    file = Repository.File.new!(%{path: op.file_path, content: op.content})
    Repository.create_file(repo, file)
  end

  def run(%Repository{} = repo, %Mutation{mode: :delete} = op) do
    Repository.delete_file(repo, op.file_path)
  end

  @spec run!(Repository.t(), Mutation.t()) :: Repository.t()
  def run!(repo, op) do
    {:ok, rpeo} = run(repo, op)
    rpeo
  end
end
