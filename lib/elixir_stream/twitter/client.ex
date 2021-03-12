defmodule ElixirStream.Twitter.Client do
  @client TwitterFinch

  @base_uri URI.parse("https://api.twitter.com")
  @update_status_uri URI.merge(@base_uri, "/1.1/statuses/update.json")

  @upload_uri URI.parse("https://upload.twitter.com")
  @upload_media_uri URI.merge(@upload_uri, "/1.1/media/upload.json")

  @chunk_size 65_536

  def update_status(status, media_ids) do
    :post
    |> Finch.build(@update_status_uri, [], %{status: status, media_ids: List.wrap(media_ids), trim_user: true})
    |> authorize_request()
    |> Finch.request(@client)
    |> handle_response()
  end

  def upload_media(file, content_type \\ nil)
  def upload_media(nil, _content_type), do: {:ok, nil}
  def upload_media(file, content_type) do
    with {:ok, media_id} when is_integer(media_id) <- init_upload(file, content_type),
         {:ok, _upload_response} <- upload_chunks(file, media_id) |> IO.inspect(label: "UPLOAD"),
         {:ok, _finalize_response} <- finalize_upload(media_id) |> IO.inspect(label: "FINALIZE") do
      {:ok, media_id}
    end
  end

  defp init_upload(file, content_type) do
    %{size: size} = File.stat!(file)
    content_type = content_type || MIME.from_path(file)
    uri = %URI{@upload_media_uri | query: URI.encode_query(%{command: "INIT", total_bytes: size, media_type: content_type})}

    :post
    |> Finch.build(uri, [], "")
    |> authorize_request()
    |> Finch.request(@client)
    |> handle_response()
    |> case do
      {:ok, %{body: %{"media_id" => media_id}}} -> {:ok, media_id}
      error -> error
    end
    |> IO.inspect(label: "INIT_UPLOAD")
  end

  defp upload_chunks(file, media_id) do
    file
    |> File.stream!([], @chunk_size)
    |> Stream.with_index()
    |> Stream.transform(0, fn {chunk, i}, _accumulator ->
      uri = %URI{@upload_media_uri | query: URI.encode_query(%{media_data: Base.encode64(chunk), segment_index: i, command: "APPEND", media_id: media_id})}
      :post
      |> Finch.build(uri, [{"Content-Type", "application/x-www-form-urlencoded"}], "")
      |> authorize_request()
      |> IO.inspect(label: "UPLOAD REQUEST")
      |> Finch.request(@client)
      |> IO.inspect(label: "UPLOAD RESPONSE")
      |> case do
        {:ok, %{code: code}} when code in 200..299 -> {[1], nil}
        {:ok, error} -> {:halt, {:error, error}}
      end
    end)
    |> Enum.to_list()
    |> IO.inspect(label: "UPLOAD RESULT")
    |> case do
      chunks when is_list(chunks) -> {:ok, Enum.sum(chunks)}
      error -> error
    end
  end

  defp finalize_upload(media_id) do
    uri = URI.merge(@upload_media_uri, URI.encode_query(%{command: "FINALIZE", media_id: media_id}))
    :post
    |> Finch.build(uri, [], "")
    |> authorize_request()
    |> IO.inspect(label: "FINALIZE REQUEST")
    |> Finch.request(@client)
    |> handle_response()
  end

  defp authorize_request(request) do
    params = URI.decode_query(request.query || "") |> IO.inspect(label: "CURRENT PARAMS")

    credentials =
      :elixir_stream
      |> Application.get_env(ElixirStream.Twitter.Client)
      |> OAuther.credentials()

    auth =
      request.method
      |> OAuther.sign(url_from_request(request), Enum.into(params, []), credentials)
      |> Enum.into(%{})
      |> IO.inspect(label: "AUTH PARAMS")

    new_query = params |> Map.merge(auth) |> URI.encode_query()

    %{request | query: new_query}
  end

  defp url_from_request(request) do
    URI
    |> struct(Map.from_struct(request))
    |> Map.update!(:scheme, fn v -> to_string(v) end)
    |> Map.put(:query, nil)
    |> to_string()
  end

  defp handle_response({:ok, %{status: code, headers: headers, body: body} = response}) when code in 200..299 do
    with [header] <- Plug.Conn.get_resp_header(%Plug.Conn{resp_headers: headers}, "content-type"),
         true <- "application/json" in String.split(header, ";") do
      {:ok, %{response | body: Jason.decode!(body)}}
    else
      _ -> response
    end
  end
  defp handle_response(response), do: response
end
