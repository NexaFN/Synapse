defmodule Synapse.MUC do
  use Ejabberd.Module
  require Record
  Record.defrecord(:iq, Record.extract(:iq, from_lib: "xmpp/include/xmpp_codec.hrl"))

  @reject_fields ["muc#roomconfig_anonymity", "muc#maxhistoryfetch"]
  @xmlns "http://jabber.org/protocol/muc#owner"

  def start(host, _opts), do: Ejabberd.Hooks.add(:user_send_packet, host, __MODULE__, :user_send_packet, 999_999)
  def stop(host), do: Ejabberd.Hooks.delete(:user_send_packet, host, __MODULE__, :user_send_packet, 999_999)

  def user_send_packet({packet = iq(sub_els: [
    {:xmlel, "query", [{"xmlns", @xmlns}, {"corr-id", id}],
     [{:xmlel, "x", [{"xmlns", "jabber:x:data"}, {"type", "submit"}], fields}]}
  ]), state}) do
    filtered = Enum.reject(fields, fn
      {:xmlel, "field", [{"var", v}, {"type", "text-single"}], _} -> v in @reject_fields
      _ -> false
    end)

    {iq(packet, sub_els: [
      {:xmlel, "query", [{"xmlns", @xmlns}, {"corr-id", id}],
       [{:xmlel, "x", [{"xmlns", "jabber:x:data"}, {"type", "submit"}], filtered}]}
    ]), state}
  end

  def user_send_packet(acc), do: acc
  def init(_), do: :ok
  def depends(_, _), do: []
  def mod_options(_), do: []
  def mod_doc, do: %{desc: 'Muc'}
end
