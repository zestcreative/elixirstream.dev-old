defmodule ElixirStream.Accounts.User do
  use ElixirStream.Schema

  @required_fields ~w[source source_id]a
  @optional_fields ~w[name avatar username twitter editor_choice]a

  schema "users" do
    field :source, Ecto.Enum, values: [:github]
    field :source_id, :string

    field :name, :string
    field :avatar, :string
    field :username, :string
    field :twitter, :string
    field :editor_choice, Ecto.Enum, values: [:gui, :emacs, :vim]

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
