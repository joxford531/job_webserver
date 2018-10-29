defmodule JobWebserver.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger

  plug(Plug.Logger, log: :debug)

  plug(:match)
  plug(:dispatch)

  match "/api/*_", to: Api.Router

  get "/hello" do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "hello from #{Node.self()}")
  end

  get "/healthz" do
    JobWebserver.Cache.server_healthy?("health_check")
      |> handle_health_check(conn)
  end

  get "/shutdown" do
    JobWebserver.Cache.kill_node_jobs()
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(200, "shutdown called by #{to_string(:inet_parse.ntoa(conn.remote_ip))}")
  end

  post "/post" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    body = Poison.decode!(body)

    result =
      hash_job_name(body)
      |> JobWebserver.Cache.server_process(body)

    case result do
      {:error, _} -> handle_job_error(conn, result)
      _ -> handle_job_created(conn, result)
    end

    conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(201, "created: #{inspect(result)}")
  end

  match _ do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(404, "not found")
  end

  defp handle_job_error(conn, {:error, reason}) do
    conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(422, "error: #{inspect(reason)}")
  end

  defp handle_job_created(conn, result) do
    conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(201, "created: #{inspect(result)}")
  end

  defp handle_health_check(_, conn) do
    conn
      |> Plug.Conn.put_resp_content_type("text/plain")
      |> Plug.Conn.send_resp(200, "Node healthy")
  end

  defp hash_job_name(body) do
    name = body["site"] <> body["unitCode"] <> body["command"] <> body["time"]
    Base.encode16(:crypto.hash(:sha256, name))
  end
end
