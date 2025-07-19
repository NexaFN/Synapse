defmodule Synapse.Presence do
  @host Application.get_env(:synapse, :ejabberd).host

  def fetch(user) do
    case resources(user) do
      [] -> {nil, nil}
      resources ->
        resource = get_highest_priority_resource(resources)
        get_presence(user, resource)
    end
  end

  def resources(user), do: :ejabberd_sm.get_user_resources(user, @host)

  defp get_highest_priority_resource(resources) do
    resources
    |> Enum.sort_by(&String.starts_with?(&1, "V2:Fortnite:WIN::Nexa."))
    |> List.first()
  end

  defp get_presence(user, resource) do
    case :ejabberd_sm.get_session_pid(user, @host, resource) do
      nil -> {nil, nil}
      session -> {:ejabberd_c2s.get_presence(session), resource}
    end
  end
end
