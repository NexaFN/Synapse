defmodule Synapse.Router do
  use Plug.Router
  require Record
  Record.defrecord(:presence, Record.extract(:presence, from_lib: "xmpp/include/xmpp_codec.hrl"))
  @host Application.get_env(:synapse, :ejabberd).host
plug CORSPlug, origin: "*"
plug :match
plug Plug.Parsers, parsers: [:json], json_decoder: Jason
plug :dispatch
plug Plug.Logger

  
  get "/health" do
    send_resp(conn, 200, "Alive")
  end
  
  get "/friends/status/:account_id" do
    case Synapse.Api.username_from_account_id(account_id) do
      nil ->
        send_resp(conn, 404, Jason.encode!(%{error: "Account not found"}))
      username ->
        raw_friends_status = Synapse.Net.get_friends_status(account_id, @host)
        
        processed_friends = process_status_data(raw_friends_status)
        
        send_resp(conn, 200, Jason.encode!( processed_friends))
    end
  end
  
  defp process_status_data(status_items) when is_list(status_items) do
    Enum.map(status_items, &process_status_item/1)
  end
  
  defp process_status_item({:text, _, json_str}) when is_binary(json_str) do
    case Jason.decode(json_str) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{error: "Failed to parse status", raw_data_type: "text tuple"}
    end
  end
  
  defp process_status_item(item) when is_map(item) do
    Enum.map(item, fn {k, v} -> {k, process_status_value(v)} end)
    |> Enum.into(%{})
  end
  
  defp process_status_item(other) do
    %{error: "Unknown status format", type: inspect(other)}
  end
  
  defp process_status_value({:text, _, json_str}) when is_binary(json_str) do
    case Jason.decode(json_str) do
      {:ok, decoded} -> decoded
      {:error, _} -> %{error: "Failed to parse embedded status"}
    end
  end
  
  defp process_status_value(value) when is_map(value) do
    Enum.map(value, fn {k, v} -> {k, process_status_value(v)} end)
    |> Enum.into(%{})
  end
  
  defp process_status_value(value) when is_list(value) do
    Enum.map(value, &process_status_value/1)
  end
  
  defp process_status_value(value), do: value
  
  get "/friends/online/:account_id" do
    case Synapse.Api.username_from_account_id(account_id) do
      nil ->
        send_resp(conn, 404, Jason.encode!(%{error: "Account not found"}))
      username ->
        online_friends = Synapse.Net.get_online_friends(account_id, @host)
        send_resp(conn, 200, Jason.encode!(%{online_friends: online_friends}))
    end
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