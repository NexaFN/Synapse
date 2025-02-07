defmodule Synapse.Modules.MUC do
  use Ejabberd.Module
  require Record

  Record.defrecord(:iq, Record.extract(:iq, from_lib: "xmpp/include/xmpp_codec.hrl"))
  Record.defrecord(:muc_owner, Record.extract(:iq, from_lib: "xmpp/include/xmpp_codec.hrl"))
  Record.defrecord(:jid, Record.extract(:jid, from_lib: "axmpp/include/jid.hrl"))

  @hook_priority 999_999
  @rejected_fields ["muc#roomconfig_anonymity", "muc#maxhistoryfetch"]

  def start(host, _opts) do
    Ejabberd.Hooks.add(:user_send_packet, host, __MODULE__, :user_send_packet, @hook_priority)
    :ok
  end

  def stop(host) do
    Ejabberd.Hooks.delete(:user_send_packet, host, __MODULE__, :user_send_packet, @hook_priority)
    :ok
  end

  def user_send_packet({iq(from: _from, sub_els: children) = packet, x} = acc) do
    case children do
      [{:xmlel, "query", query_attrs, [{:xmlel, "x", x_attrs, fields}]}]
      when query_attrs == [
             {"xmlns", "http://jabber.org/protocol/muc#owner"},
             {"corr-id", _corr_id}
           ] and
           x_attrs == [{"xmlns", "jabber:x:data"}, {"type", "submit"}] ->
        filtered_fields = Enum.reject(fields, &maybe_reject_field/1)
        {iq(packet, sub_els: [build_query_element(query_attrs, filtered_fields)]), x}

      _other -> acc
    end
  end

  def user_send_packet(acc), do: acc

  defp maybe_reject_field({:xmlel, "field", [{"var", name}, {"type", "text-single"}], _})
       when name in @rejected_fields,
       do: true
  defp maybe_reject_field(_), do: false

  defp build_query_element(query_attrs, fields) do
    {:xmlel, "query", query_attrs,
     [{:xmlel, "x", [{"xmlns", "jabber:x:data"}, {"type", "submit"}], fields}]}
  end

  def init(_), do: :ok
  def depends(_host, _opts), do: []
  def mod_options(_host), do: []
  def mod_doc, do: %{desc: 'This is just a demonstration.'}
end
