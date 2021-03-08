defmodule ElixirStream.Storage do
  @type file :: Path.t()
  @type key :: String.t()

  @callback get(key) :: {:ok, file} | {:error, term}
  @callback put(key, file) :: {:ok, file} | {:error, term}

  defp impl(), do: Application.get_env(:elixir_stream, :storage)

  def get(key) do
    impl().get(key)
  end

  def put(key, file) do
    impl().put(key, file)
  end
end
