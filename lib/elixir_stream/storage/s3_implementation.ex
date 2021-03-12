defmodule ElixirStream.Storage.S3Implementation do
  @moduledoc """
  # Temporary Files

  There is a Lifecycle Configuration applied to the bucket to auto-delete
  any files that are prefixed with "tmp"

  `s3cmd setlifecycle priv/storage/lifecycle_policy.xml s3://elixirstream.dev`
  `s3cmd -c ~/.s3cfg-prod setlifecycle priv/storage/lifecycle_policy.xml s3://elixirstream.dev-prod`
  """
  @behaviour ElixirStream.Storage
  @bucket Application.compile_env(:elixir_stream, ElixirStream.Storage)[:bucket]

  @doc """
  Available options:

    max_concurrency: pos_integer(),
    chunk_size: pos_integer(),
    timeout: pos_integer()
  """
  def download(remote_path, local_path, opts \\ []) do
    ExAws.S3.download_file(@bucket, remote_path, local_path, opts)
  end

  @doc """
  Available options:

      expires_in: integer(),
      virtual_host: boolean(),
      query_params: [{binary(), binary()}],
      headers: [{binary(), binary()}]
  """
  def url(key, opts \\ []) do
    :s3
    |> ExAws.Config.new()
    |> ExAws.S3.presigned_url(:get, @bucket, key, opts)
  end

  # Example result
  #  %{body: %{
  #   bucket: "elixirstream.dev",
  #   eTag: "db79b652855091460f91f6a89d88ffae-1",
  #   key: "codeshots/tmp.5wNK2Ge4sh.png",
  #   location: "us-east-1.linodeobjects.com/elixirstream.dev/codeshots/tmp.5wNK2Ge4sh.png"
  # }}
  def upload(local_file, remote_path, opts \\ []) do
    local_file
    |> ExAws.S3.Upload.stream_file(opts)
    |> ExAws.S3.upload(@bucket, remote_path, opts)
    |> ExAws.request(opts)
    |> ExAws.S3.Parsers.parse_upload()
  end
end
