defmodule ElixirStream.Catalog do
  alias ElixirStream.Catalog.Tip
  alias ElixirStream.Repo
  alias Phoenix.PubSub
  @tip_topic "tips"

  @spec find_tip(String.t()) :: nil | %Tip{}
  def find_tip(id),
    do: Repo.get(Tip, id)

  @spec list_tips() :: list(%Tip{})
  def list_tips() do
    Tip
    |> Repo.all()
    |> Repo.preload(:contributor)
  end

  @spec create_tip(map()) :: {:ok, %Tip{}}
  def create_tip(attrs) do
    %Tip{}
    |> Tip.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tip} ->
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :new, tip])
        {:ok, tip}
      error ->
        error
    end
  end
end
