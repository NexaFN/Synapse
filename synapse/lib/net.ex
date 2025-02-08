defmodule Synapse.Net do
  use Ejabberd.Module
  require Record

  for {name, lib} <- [roster: "ejabberd/include/mod_roster.hrl",
                      roster_item: "xmpp/include/xmpp_codec.hrl",
                      message: "xmpp/include/xmpp_codec.hrl"] do
    Record.defrecord(name, Record.extract(name, from_lib: lib))
  end

  @priorities [roster: 99999, presence: 50]

  def start(host, _opts), do: info(~c"Starting ejabberd module Roster") && add_hooks(host)
  def stop(host), do: info(~c"Stopping ejabberd module Roster") && remove_hooks(host)
  def unset_presence(user, _server, _resource, _packet), do: Synapse.Tracker.remove(user) && :none
  def on_presence(_user, _server, "V2:Fortnite:WIN::Solaris." <> _rest, _packet), do: :none

  def on_presence(user, server, resource, packet) do
    unless Synapse.Tracker.check(user) do
      process_friends_presence(user, server, resource, packet)
      Synapse.Tracker.set(user)
    end
    :none
  end

  def roster_get(acc, {user, server}), do: acc ++ build_user_roster(user, server)

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
          roster_item(jid: jid_string(friend, server, r), name: friend, subscription: :both)
        end)
    end
  end

  defp process_friends_presence(user, server, resource, packet) do
    user
    |> Synapse.Api.friends()
    |> Enum.each(&handle_friend_presence(&1, user, server, resource, packet))
  end

  defp handle_friend_presence(friend, user, server, resource, packet) do
    with resources when resources != [] <- :ejabberd_sm.get_user_resources(friend, server),
         friend_resource when not is_nil(friend_resource) <- find_friend_resource(resources) do
      try do
        route_presence(friend, user, server, resource, friend_resource, packet)
      catch _any -> IO.inspect("crashed")
      end
    end
  end

  defp find_friend_resource([resource]), do: resource
  defp find_friend_resource(resources), do: Enum.find(resources, &(not String.starts_with?(&1, "V2:Fortnite:WIN::Solaris.")))

  defp route_presence(friend, user, server, resource, friend_resource, packet) do
    presence = if user == friend, do: packet, else: get_friend_presence(friend, server, friend_resource) |> :ejabberd_c2s.get_presence()
    :ejabberd_router.route(
      jid_string(friend, server, friend_resource) |> :jid.from_string(),
      jid_string(user, server, resource) |> :jid.from_string(),
      presence
    )
  end

  defp get_friend_presence(friend, server, resource), do: :ejabberd_sm.get_session_pid(friend, server, resource)
  defp jid_string(user, server, resource), do: "#{user}@#{server}/#{resource}"

  defp add_hooks(host) do
    Enum.each([roster_get: :roster_get, set_presence_hook: :on_presence, unset_presence_hook: :unset_presence], fn {hook, fun} ->
      Ejabberd.Hooks.add(hook, host, __MODULE__, fun, @priorities[hook == :roster_get && :roster || :presence])
    end)
  end

  defp remove_hooks(host) do
    Enum.each([roster_get: :roster_get, set_presence_hook: :on_presence, unset_presence_hook: :unset_presence], fn {hook, fun} ->
      Ejabberd.Hooks.delete(hook, host, __MODULE__, fun, @priorities[hook == :roster_get && :roster || :presence])
    end)
  end

  def depends(_host, _opts), do: []
  def mod_options(_host), do: []
  def mod_doc, do: %{desc: ~c"This is just a demonstration."}
end
