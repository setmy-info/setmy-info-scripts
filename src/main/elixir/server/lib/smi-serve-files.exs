Mix.install([
  {:bandit, "~> 1.8"},
  {:plug, "~> 1.18"}
])

defmodule SmiServeFiles do
  @moduledoc """
  Serves one web root over HTTP, for a reverse proxy to sit in front of.

  Everything under the given directory is public. The application's working directory is a
  sibling of it, not a child, so nothing writable by the service user is reachable from here.

  Binds to the loopback address only: nothing reaches this server except through the proxy.
  """

  use Plug.Router

  @default_port 8130

  plug :serve_static
  plug :match
  plug :dispatch

  @doc """
  Takes the command line arguments and returns {directory, port}.
  """
  def parse([directory]), do: {directory, @default_port}
  def parse([directory, port]), do: {directory, String.to_integer(port)}

  @doc """
  Stores what every request needs, so that it is built once instead of per request.
  """
  def configure(directory) do
    :persistent_term.put({__MODULE__, :static}, Plug.Static.init(at: "/", from: directory))
    :persistent_term.put({__MODULE__, :index}, Path.join(directory, "index.html"))
    directory
  end

  def serve_static(conn, _opts) do
    Plug.Static.call(conn, :persistent_term.get({__MODULE__, :static}))
  end

  # Anything the static plug did not answer is a client side route: the single page app is
  # handed its index.html and resolves the path itself.
  get _ do
    index = :persistent_term.get({__MODULE__, :index})

    if File.regular?(index) do
      conn |> put_resp_content_type("text/html") |> send_file(200, index)
    else
      send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end
end

{directory, port} = SmiServeFiles.parse(System.argv())

unless File.dir?(directory) do
  IO.puts(:stderr, "ERROR: not a directory: #{directory}")
  System.halt(1)
end

directory
|> Path.expand()
|> SmiServeFiles.configure()

{:ok, _} =
  Bandit.start_link(
    plug: SmiServeFiles,
    scheme: :http,
    ip: {127, 0, 0, 1},
    port: port
  )

IO.puts("Serving #{Path.expand(directory)} on http://127.0.0.1:#{port} as #{System.get_env("USER")}")

Process.sleep(:infinity)
