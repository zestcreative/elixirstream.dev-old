defmodule ElixirStream.Twitter.Client do
  @client TwitterFinch

  @base_uri URI.parse("https://api.twitter.com")
  @update_status_uri URI.merge(@base_uri, "/1.1/statuses/update.json")

  @upload_uri URI.parse("https://upload.twitter.com")
  @upload_media_uri URI.merge(@base_uri, "/1.1/media/upload.json")

  @one_mb 1_048_576

  def update_status(status, media_ids \\ []) do
    params = %{
      status: status,
      media_ids: media_ids,
      trim_user: true,
    }

    :post
    |> Finch.build(@update_status_uri, [], params)
    |> authorize_request()
    |> Finch.request(@client)
  end

  def upload_file(file) do
    with {:ok, init_response} <- init_upload(file),
         {:ok, upload_response} <- upload_chunks(init_response, file),
         {:ok, finalize_response} <- finalize_upload(init_response) do
      {:ok, finalize_response}
    end
  end

  defp init_upload(file) do
    %{size: size} = File.stat!(file)
    params = %{command: "INIT", total_bytes: size, media_type: "image/png"}

    :post
    |> Finch.build(@upload_media_uri, [], params)
    |> authorize_request()
    |> Finch.request(@client)
  end

  defp upload_chunks(init_response, file) do
    base_params = %{command: "APPEND", media_id: init_response["media_id"]}

    file
    |> File.stream!([], @one_mb)
    |> Stream.with_index()
    |> Stream.each(fn {chunk, i} ->
      params =
        base_params
        |> Map.put(:media, chunk)
        |> Map.put(:segment_index, i)

      :post
      |> Finch.build(@upload_media_uri, [], params)
      |> authorize_request()
      |> Finch.request(@client)
    end)
  end

  defp finalize_upload(init_response) do
    params = %{command: "FINALIZE", media_id: init_response["media_id"]}

    :post
    |> Finch.build(@upload_media_uri, [], params)
    |> authorize_request()
    |> Finch.request(@client)
  end

  defp authorize_request(request) do
    # TODO
    request
  end
end
