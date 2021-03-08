defmodule ElixirStream.Storage.LocalImplementation do
  @behaviour ElixirStream.Storage

  def get(key) do
    path = Path.join([dir(), key])

    if File.regular?(path) do
      {:ok, path}
    else
      {:error, :not_found}
    end
  end

  def put(key, file_path) do
    filename = key <> Path.extname(file_path)
    destination_abs = Path.join([dir(), filename])

    File.mkdir_p!(dir())
    File.cp!(file_path, destination_abs)
    {:ok, "/" <> Path.join(["uploads", "codeshots", filename])}
  end

  defp dir() do
    Path.join(Application.get_env(:elixir_stream, :storage_dir), "codeshots")
  end
end
