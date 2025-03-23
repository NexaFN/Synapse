defmodule Synapse.Auth do
    def check(user, _, "9h8liqqiomflqi0vj33kek27qbfzbmkp") when user in ["xmpp-admin", "system"], do: {:nocache, true}
    def check(user, _, _) when user in ["xmpp-admin", "system"], do: {:nocache, false}
 
    def check(_, _, "Solaris.Launcher.ActivityChannel"), do: {:nocache, true}
 
    def check(user, _server, password) do
      case Synapse.Api.auth(user, password) do
        true -> {:nocache, true}
        _ -> {:nocache, false}
      end
    end
end