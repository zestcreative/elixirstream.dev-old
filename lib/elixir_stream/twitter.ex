defmodule ElixirStream.Twitter do
  alias ElixirStream.Silicon
  alias ElixirStream.Twitter.Client
  alias ElixirStreamWeb.Router.Helpers, as: Routes
  @endpoint ElixirStreamWeb.Endpoint

  def publish(tip) do
    with {:ok, file} <- Silicon.generate(tip),
         {:ok, media_id} <- Client.upload_media(file) do
         # {:ok, response} <- Client.update_status(tweet_body(tip), [media_id]) do
      # IO.inspect(response, label: "STATUS UPDATE RESPONSE")Q
      :ok
    end
  end

  defp tweet_body(tip) do
    []
    |> put_title(tip)
    |> put_contributor(tip)
    |> put_url(tip)
    |> fill_with_description(tip)
    |> Enum.join()
  end

  def put_title(body, %{title: title}), do: [["\"", title, "\""] | body]

  def put_contributor(body, %{contributor: %{name: name, twitter: nil}}), do: [" by #{name}" | body]
  def put_contributor(body, %{contributor: %{twitter: twitter}}), do: [" by @#{twitter}" | body]

  def put_url(body, %{id: tip_id}), do: [Routes.tip_path(@endpoint, :show, tip_id) | body]

  @tweet_limit 280
  def fill_with_description(body, %{description: description}) do
    description = "\n\n #{description}"
    taken_chars = body |> Enum.join() |> String.length()
    remaining_chars = @tweet_limit - taken_chars
    if String.length(description) > remaining_chars do
      {truncated, _} = String.split_at(description, remaining_chars - 3)
      [truncated <> "..." | body]
    else
      [description | body]
    end
  end
end
