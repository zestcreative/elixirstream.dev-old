defmodule ElixirStream.Silicon do
  require Logger
  @silicon_bin "bin/silicon.sh"

  def generate(tip, opts \\ [])
  def generate(%{code: nil}, _opts), do: {:ok, nil}
  def generate(tip, opts) do
    theme = Keyword.get(opts, :theme, "Monokai Extended Bright")
    extension = Keyword.get(opts, :extension, "ex")

    @silicon_bin
    |> path_for()
    |> Path.expand()
    |> System.cmd([tip.code, theme, extension])
    |> case do
      {filepath, 0} ->
        {:ok, String.trim(filepath)}
      {output, _} ->
        Logger.error(output)
        {:error, "could not generate image"}
    end
  end

  def path_for(relative_path) do
    if Application.get_env(:elixir_stream, :app_env) == :prod do
      relative_path
    else
      Path.join(["rel", "overlays", relative_path])
    end
  end
end
