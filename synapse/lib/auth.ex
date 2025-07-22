defmodule Synapse.Auth do
    def check(user, _, password) when user in ["xmpp-admin", "system"] do
      if password == System.get_env("S_TOKEN") do
        {:nocache, true}
      else
        {:nocache, false}
      end
    end
  
    def check(user, _server, password) do
      case Synapse.Api.auth(user, password) do
        true -> {:nocache, true}
        _ -> {:nocache, false}
      end
    end
end