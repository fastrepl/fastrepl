defmodule Fastrepl.Config do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @type t :: %Config{
          version: pos_integer(),
          base_branch: String.t(),
          ignored_paths: [String.t()]
        }

  @primary_key false
  embedded_schema do
    field :version, :integer, default: 1
    field :base_branch, :string
    field :ignored_paths, {:array, :string}, default: []
  end

  def parse(str) do
    case YamlElixir.read_from_string(str) do
      {:ok, config} ->
        try do
          cs = changeset(%Config{}, config)

          if cs.valid? do
            {:ok, apply_changes(cs)}
          else
            {:error, cs}
          end
        rescue
          _ -> {:error, :invalid_yaml}
        end

      {:error, _} ->
        {:error, :invalid_yaml}
    end
  end

  def changeset(config, attrs) do
    config
    |> cast(attrs, [:version, :base_branch, :ignored_paths])
    |> validate_required([:version, :base_branch])
    |> validate_number(:version, equal_to: 1)
    |> validate_config()
  end

  defp validate_config(changeset) do
    version = get_field(changeset, :version)
    changeset |> validate_fields_by_version(version)
  end

  defp validate_fields_by_version(changeset, 1) do
    changeset
    |> validate_length(:base_branch, min: 1)
  end
end
