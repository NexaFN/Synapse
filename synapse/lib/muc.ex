defmodule Synapse.MUC do
  use Ejabberd.Module

  require Record

  Record.defrecord(
    :iq,
    Record.extract(:iq, from_lib: "xmpp/include/xmpp_codec.hrl")
  )

  Record.defrecord(
    :muc_owner,
    Record.extract(:iq, from_lib: "xmpp/include/xmpp_codec.hrl")
  )

  Record.defrecord(
    :jid,
    Record.extract(:jid, from_lib: "xmpp/include/jid.hrl")
  )

  def start(host, _opts) do
    Ejabberd.Hooks.add(:user_send_packet, host, __MODULE__, :user_send_packet, 999_999)
    :ok
  end

  def user_send_packet({iq(from: _from, sub_els: children) = packet, x} = acc) do
    case children do
      [
        {:xmlel, "query",
         [
           {"xmlns", "http://jabber.org/protocol/muc#owner"},
           {"corr-id", corr_id}
         ], [{:xmlel, "x", [{"xmlns", "jabber:x:data"}, {"type", "submit"}], fields}]}
      ] ->
        fields = Enum.reject(fields, &maybe_reject_field/1)

        {iq(packet,
           sub_els: [
             {:xmlel, "query",
              [
                {"xmlns", "http://jabber.org/protocol/muc#owner"},
                {"corr-id", corr_id}
              ], [{:xmlel, "x", [{"xmlns", "jabber:x:data"}, {"type", "submit"}], fields}]}
           ]
         ), x}

      _ ->
        acc
    end
  end

  def user_send_packet(acc), do: acc

  defp maybe_reject_field({:xmlel, "field", [{"var", name}, {"type", "text-single"}], _})
       when name in ["muc#roomconfig_anonymity", "muc#maxhistoryfetch"],
       do: true

  defp maybe_reject_field(_), do: false

  def stop(host) do
    Ejabberd.Hooks.delete(:user_send_packet, host, __MODULE__, :user_send_packet, 999_999)
    :ok
  end

  def init(_) do
    :ok
  end

  def depends(_host, _opts) do
    []
  end

  def mod_options(_host) do
    []
  end

  def mod_doc() do
    %{:desc => 'This is just a demonstration.'}
  end
end
