defmodule ElixirStream.Catalog.Upvote do
  use ElixirStream.Schema
  alias ElixirStream.Accounts
  alias ElixirStream.Catalog

  @optional_fields ~w[user_id tip_id]a

  schema "tip_upvotes" do
    belongs_to :user, Accounts.User
    belongs_to :tip, Catalog.Tip

    timestamps()
  end

  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields)
    |> assoc_constraint(:user)
    |> assoc_constraint(:tip)
    |> unique_constraint([:tip_id, :user_id], message: "is already upvoted by user")
  end
end
