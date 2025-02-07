defmodule Synapse.Roster do
  use Ejabberd.Module
  require Record

  Record.defrecord(:roster, Record.extract(:roster, from_lib: "ejabberd/include/mod_roster.hrl"))
  Record.defrecord(:roster_item, Record.extract(:roster_item, from_lib: "xmpp/include/xmpp_codec.hrl"))
  Record.defrecord(:message, Record.extract(:message, from_lib: "xmpp/include/xmpp_codec.hrl"))

  @roster_priority 99999
  @presence_priority 50

  def start(host, _opts) do
    info(~c"Starting ejabberd module Roster")
    add_hooks(host)
    :ok
  end

  def stop(host) do
    info(~c"Stopping ejabberd module Roster")
    remove_hooks(host)
    :ok
  end

  def unset_presence(user, _server, _resource, _packet) do
    Synapse.Counter.remove(user)
    :none
  end

  def on_presence(_user, _server, "V2:Fortnite:WIN::Solaris." <> _rest, _packet), do: :none
  def on_presence(user, server, resource, packet) do
    unless Synapse.Counter.check(user) do
      process_friends_presence(user, server, resource, packet)
      Synapse.Counter.set(user)
    end
    :none
  end

  def roster_get(acc, {user, server}) do
    acc ++ build_user_roster(user, server)
  end

  defp build_user_roster(user, server) do
    user
    |> Synapse.Api.friends()
    |> Enum.flat_map(&create_roster_items(&1, server))
    |> Enum.reject(&is_nil/1)
  end

  defp create_roster_items(friend, server) do
    case :ejabberd_sm.get_user_resources(friend, server) do
      [] -> []
      resources ->
        Enum.map(resources, fn r ->
          roster_item(
            jid: :jid.from_string("#{friend}@#{server}/#{r}"),
            name: friend,
            subscription: :both
          )
        end)
    end
  end

  defp process_friends_presence(user, server, resource, packet) do
    Synapse.Api.friends(user)
    |> Enum.each(&handle_friend_presence(&1, user, server, resource, packet))
  end

  defp handle_friend_presence(friend, user, server, resource, packet) do
    with resources when resources != [] <- :ejabberd_sm.get_user_resources(friend, server),
         friend_resource when not is_nil(friend_resource) <- find_friend_resource(resources) do
      try do
        route_presence(friend, user, server, resource, friend_resource, packet)
      catch
        _ -> IO.inspect("crashed")
      end
    end
  end

  defp find_friend_resource([resource]), do: resource
  defp find_friend_resource(resources) do
    Enum.find(resources, &(not String.starts_with?(&1, "V2:Fortnite:WIN::Solaris.")))
  end

  defp route_presence(friend, user, server, resource, friend_resource, packet) do
    from_jid = :jid.from_string("#{friend}@#{server}/#{friend_resource}")
    to_jid = :jid.from_string("#{user}@#{server}/#{resource}")

    presence = if user == friend do
      packet
    else
      friend
      |> get_friend_presence(server, friend_resource)
      |> :ejabberd_c2s.get_presence()
    end

    :ejabberd_router.route(from_jid, to_jid, presence)
  end

  defp get_friend_presence(friend, server, resource) do
    :ejabberd_sm.get_session_pid(friend, server, resource)
  end

  defp add_hooks(host) do
    Ejabberd.Hooks.add(:roster_get, host, __MODULE__, :roster_get, @roster_priority)
    Ejabberd.Hooks.add(:set_presence_hook, host, __MODULE__, :on_presence, @presence_priority)
    Ejabberd.Hooks.add(:unset_presence_hook, host, __MODULE__, :unset_presence, @presence_priority)
  end

  defp remove_hooks(host) do
    Ejabberd.Hooks.delete(:roster_get, host, __MODULE__, :roster_get, @roster_priority)
    Ejabberd.Hooks.delete(:set_presence_hook, host, __MODULE__, :on_presence, @presence_priority)
    Ejabberd.Hooks.delete(:unset_presence_hook, host, __MODULE__, :unset_presence, @presence_priority)
  end

  def depends(_host, _opts), do: []
  def mod_options(_host), do: []
  def mod_doc, do: %{desc: ~c"This is just a demonstration."}
end
