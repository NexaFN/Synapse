defmodule Synapse.Api do
  use HTTPoison.Base

  @token "skibiditoliet"
  @base_url "https://avalon-external-api.solarisfn.org/s/api/synapse"

  def endpoint, do: @base_url

  def process_request_url(path), do: endpoint() <> path

  def process_request_headers(headers) do
    Keyword.merge(headers, [{"x-synapse", @token}])
  end

  def friends("xmpp-admin"), do: []
  def friends(user) do
    with {:ok, %{status_code: 200, body: body}} <- get("/#{user}/friends"),
         {:ok, decoded} <- Jason.decode(body),
         data when is_list(data) <- Map.get(decoded, "data") do
      data
    else
      _error -> []
    end
  end

  def auth(user, password) do
    case post("/#{user}/auth?password=#{password}", []) do
      {:ok, %{status_code: 204}} -> true
      _error -> false
    end
  end
end
