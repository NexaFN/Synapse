defmodule Synapse.Api do
  use HTTPoison.Base
  @token "9h8liqqiomflqi0vj33kek27qbfzbmkp"
  @base_url "https://horizon-testing.solarisfn.org:8443/s/api/synapse"
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
  def username_from_account_id(account_id) do
    ""
  end
  def account_id_from_username(username) do
    with {:ok, %{status_code: 200, body: body}} <- get("/user/#{username}/account_id"),
         {:ok, decoded} <- Jason.decode(body),
         account_id when is_binary(account_id) <- Map.get(decoded, "account_id") do
      account_id
    else
      _error -> nil
    end
  end
end