defmodule ElixirStream.Accounts.UserTest do
  use ElixirStream.DataCase
  alias ElixirStream.Accounts.User
  doctest User

  describe "changeset" do
    test "requires uniqueness by source and source_id" do
      _existing = Factory.insert(:user, source: "github", source_id: "1")
      params = Factory.params_for(:user, source: "github", source_id: "1")

      assert {:error, changeset} = %User{} |> User.changeset(params) |> Repo.insert()
      assert %{source_id: ["already has an account"]} = errors_on(changeset)
    end

    test "has requirements" do
      params = Factory.params_for(:user, source: nil, source_id: nil)
      assert {:error, changeset} = %User{} |> User.changeset(params) |> User.apply()

      assert %{
               source_id: ["can't be blank"],
               source: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "only allows github source" do
      params = Factory.params_for(:user, source: "bitbucket", source_id: "1")
      assert {:error, changeset} = %User{} |> User.changeset(params) |> User.apply()

      assert %{source: ["is invalid"]} = errors_on(changeset)
    end
  end
end
