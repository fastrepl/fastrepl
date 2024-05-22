defmodule Fastrepl.Config do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  @type t :: %Config{}

  @primary_key false
  embedded_schema do
    field :version, :integer
    field :issue_delay_seconds, :integer, default: 180
    field :ignored_paths, {:array, :string}, default: []
  end

  def parse(str) do
    case YamlElixir.read_from_string(str) do
      {:ok, config} ->
        cs = changeset(%Config{}, config)

        if cs.valid? do
          {:ok, apply_changes(cs)}
        else
          {:error, cs}
        end

      {:error, error} ->
        {:error, error}
    end
  end

  def parse!(str) do
    {:ok, config} = parse(str)
    config
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:version, :issue_delay_seconds, :ignored_paths])
    |> validate_required([:version])
    |> validate_number(:version, equal_to: 1)
    |> validate_number(:issue_delay_seconds, greater_than: 0)
  end
end
