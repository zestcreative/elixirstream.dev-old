defmodule ElixirStream.Schema do
  @moduledoc "Ecto Schema Helpers"

  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:id, :binary_id, read_after_writes: true}
      @foreign_key_type :binary_id
      @timestamp_opts [type: :utc_datetime_usec]
    end
  end
end
