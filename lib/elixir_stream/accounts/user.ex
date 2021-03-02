defmodule ElixirStream.Accounts.User do
  use ElixirStream.Schema

  @required_fields ~w[source source_id]a
  @optional_fields ~w[name avatar username]a

  schema "users" do
    field :source, Ecto.Enum, values: [:github]
    field :source_id, :string

    field :name, :string
    field :avatar, :string
    field :username, :string

    timestamps()
  end

  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:source_id, :source], message: "already has an account")
  end

  def apply(changeset), do: apply_action(changeset, :insert)
end
