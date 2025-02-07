defmodule Synapse.Router do
  use Plug.Router
  require Record

  Record.defrecord(:presence, Record.extract(:presence, from_lib: "xmpp/include/xmpp_codec.hrl"))

  @host Application.get_env(:synapse, :ejabberd).host

  plug :match
  plug :dispatch
  plug Plug.Logger

  get "/health" do
    send_resp(conn, 200, "Alive")
  end

  post "/forward_presence_stanza/:from/:to" do
    case Synapse.Presence.fetch(from) do
      {nil, nil} -> nil
      {presence, resource} ->
        route_presence(from, to, resource, presence)
    end

    send_resp(conn, 204, "")
  end

  post "/forward_offline_presence_stanza/:from/:to" do
    stanza = presence(type: :unavailable)

    from
    |> Synapse.Presence.resources()
    |> Enum.each(&route_presence(from, to, &1, stanza))

    send_resp(conn, 204, "")
  end

  match _ do
    send_resp(conn, 404, "Not Found")
  end

  defp route_presence(from, to, resource, presence) do
    :ejabberd_router.route(
      :jid.from_string("#{from}@#{@host}/#{resource}"),
      :jid.from_string("#{to}@#{@host}"),
      presence
    )
  end
end
