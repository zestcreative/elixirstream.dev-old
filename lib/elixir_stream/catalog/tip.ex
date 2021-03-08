defmodule ElixirStream.Catalog.Tip do
  use ElixirStream.Schema

  @required_fields ~w[title description code]a
  @optional_fields ~w[published_at]a

  schema "tips" do
    field :title, :string
    field :description, :string
    field :code, :string
    field :code_image_url, :string

    field :published_at, :utc_datetime_usec

    belongs_to :contributor, ElixirStream.Accounts.User
    # has_many :modules, Catalog.Modules

    timestamps()
  end

  def changeset(struct_or_changeset, attrs) do
    struct_or_changeset
    |> cast(attrs, @optional_fields ++ @required_fields)
    |> cast_assoc(:modules)
    |> validate_required(@required_fields)
    |> ensure_published_at()
  end

  defp ensure_published_at(changeset) do
    case get_field(changeset, :published_at) do
      nil -> put_change(changeset, :published_at, DateTime.utc_now())
      _date -> changeset
    end
  end

  def apply(changeset), do: apply_action(changeset, :insert)
end
