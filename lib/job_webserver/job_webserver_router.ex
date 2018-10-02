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
    |> Plug.Conn.send_resp(200, "hello world")
  end

  post "/post" do
    {:ok, body, conn} = Plug.Conn.read_body(conn)
    body = Poison.decode!(body)

    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(201, "created: #{get_in(body, ["message"])}")
  end

  match _ do
    conn
    |> Plug.Conn.put_resp_content_type("text/plain")
    |> Plug.Conn.send_resp(404, "not found")
  end
end
