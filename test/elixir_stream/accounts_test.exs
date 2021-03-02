defmodule ElixirStream.AccountsTest do
  use ElixirStream.DataCase
  alias ElixirStream.Accounts

  doctest Accounts

  describe "admin?" do
    test "should only return true for dbernheisel" do
      user = Factory.build(:user)
      refute Accounts.admin?(user)

      user = Factory.build(:user, source: "github", source_id: "643967")
      assert Accounts.admin?(user)
    end
  end

  describe "find_or_create" do
    test "when not found, creates" do
      auth = Factory.build(:github_auth)
      refute Accounts.find(to_string(auth.provider), to_string(auth.uid))

      assert {:ok, user} = Accounts.find_or_create(auth)
      assert user.source == auth.provider
      assert user.source_id == to_string(auth.uid)
      assert user.avatar == auth.info.urls.avatar_url
      assert user.username == auth.info.nickname
      assert user.name == auth.info.name
    end

    test "when found, returns existing" do
      auth = Factory.build(:github_auth)
      %{id: existing_id} = Factory.insert(:user, username: "foo", source: auth.provider, source_id: to_string(auth.uid))

      assert {:ok, %{id: ^existing_id, username: "foo"}} = Accounts.find_or_create(auth)
    end
  end
end