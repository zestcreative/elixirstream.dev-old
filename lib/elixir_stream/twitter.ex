defmodule ElixirStream.Twitter do
  alias ElixirStream.Catalog
  alias ElixirStream.Twitter.Client
  alias ElixirStreamWeb.Router.Helpers, as: Routes
  @endpoint ElixirStreamWeb.Endpoint

  def publish(tip) do
    if config()[:publish] do
      with {:ok, tip, file} <- Catalog.generate_codeshot(tip),
          {:ok, media_id} <-
            Client.upload_media(file, filename: url_safe(tip.title) <> Path.extname(file)),
          {:ok, %{body: %{"id_str" => twitter_status_id}}} <-
            Client.update_status(tweet_body(tip), [media_id]),
          {:ok, tip} <- Catalog.add_twitter_status_id(tip, twitter_status_id) do
        {:ok, tip}
      end
    else
      {:ok, tip}
    end
  end

  defp url_safe(string) do
    string = string |> String.replace(" ", "-") |> String.downcase()
    Regex.replace(~r/[^a-zA-Z0-9_-]/, string, "")
  end

  def tweet_body(tip) do
    []
    |> put_url(tip)
    |> put_contributor(tip)
    |> put_title(tip)
    |> Enum.join()
    |> fill_with_description(tip)
  end

  def put_title(body, %{title: title}), do: [title | body]

  def put_contributor(body, %{contributor: %{name: name, twitter: nil}}),
    do: [" by #{name}" | body]

  def put_contributor(body, %{contributor: %{twitter: twitter}}), do: [" by @#{twitter}" | body]

  def put_url(body, %{id: tip_id}), do: [" ", Routes.tip_url(@endpoint, :show, tip_id) | body]

  @tweet_limit 280
  def fill_with_description(body, %{description: description}) do
    description = "\n\n#{description}"
    taken_chars = String.length(body)
    remaining_chars = @tweet_limit - taken_chars

    if String.length(description) > remaining_chars do
      truncated = description |> String.split() |> Enum.drop(-1) |> Enum.join(" ")

      if String.last(truncated) == "." do
        body <> "\n\n" <> truncated
      else
        body <> "\n\n" <> truncated <> "..."
      end
    else
      body <> description
    end
  end

  defp config, do: Application.get_env(:elixir_stream, __MODULE__)
end
