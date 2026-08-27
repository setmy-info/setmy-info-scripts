Mix.install([
  {:bandit, "~> 1.8"},
  {:plug, "~> 1.18"}
])

[directory, port] = System.argv()

defmodule SmiServeFiles do
  use Plug.Router

  @directory Path.expand(directory)
  @index Path.join(@directory, "index.html")
  @max_depth 16
  @max_path 2048

  plug :guard_path
  plug :nosniff
  plug :keep_method
  plug Plug.Head
  plug Plug.Static, at: "/", from: @directory
  plug :match
  plug :dispatch

  def guard_path(conn, _opts) do
    if byte_size(conn.request_path) > @max_path or length(conn.path_info) > @max_depth or
         Enum.any?(conn.path_info, &bad_segment?/1) do
      conn |> send_resp(404, "Not Found") |> halt()
    else
      conn
    end
  end

  defp bad_segment?(segment) do
    decoded = URI.decode(segment)

    decoded == "" or String.starts_with?(decoded, ".") or
      String.contains?(decoded, ["/", "\\", ":"]) or not String.printable?(decoded) or
      String.to_charlist(decoded) |> Enum.any?(&(&1 < 0x20 or &1 == 0x7F))
  end

  def nosniff(conn, _opts), do: put_resp_header(conn, "x-content-type-options", "nosniff")

  def keep_method(conn, _opts), do: assign(conn, :method, conn.method)

  def access_log(_event, %{resp_body_bytes: bytes}, %{conn: conn}, _config) do
    time = Calendar.strftime(DateTime.utc_now(), "%d/%b/%Y:%H:%M:%S %z")
    referer = clean(List.first(get_req_header(conn, "referer")) || "-")
    agent = clean(List.first(get_req_header(conn, "user-agent")) || "-")
    method = conn.assigns[:method] || conn.method
    IO.puts(~s(#{client_ip(conn)} - - [#{time}] "#{method} #{clean(conn.request_path)} HTTP/1.1" #{conn.status} #{bytes} "#{referer}" "#{agent}"))
  end

  def access_log(_event, _measurements, _metadata, _config), do: :ok

  defp client_ip(conn) do
    case get_req_header(conn, "x-forwarded-for") do
      [] -> :inet.ntoa(conn.remote_ip)
      list -> list |> Enum.join(",") |> String.split(",") |> List.last() |> String.trim() |> clean()
    end
  end

  defp clean(text), do: String.replace(text, ~r/[^\x20-\x7e]|"/, "?")

  get _ do
    if File.regular?(@index) do
      conn |> put_resp_content_type("text/html") |> send_file(200, @index)
    else
      send_resp(conn, 404, "Not Found")
    end
  end

  match _ do
    conn |> put_resp_header("allow", "GET, HEAD") |> send_resp(405, "Method Not Allowed")
  end
end

:telemetry.attach("access-log", [:bandit, :request, :stop], &SmiServeFiles.access_log/4, nil)

{:ok, _} =
  Bandit.start_link(
    plug: SmiServeFiles,
    scheme: :http,
    ip: {127, 0, 0, 1},
    port: String.to_integer(port),
    http_2_options: [enabled: false],
    websocket_options: [enabled: false]
  )

IO.puts("Serving #{Path.expand(directory)} on http://127.0.0.1:#{port} as #{System.get_env("USER")}")

Process.sleep(:infinity)
