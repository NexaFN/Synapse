defmodule Synapse.Counter do
  use GenServer

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  end

  def set(user), do: GenServer.cast(__MODULE__, {:set, user})
  def reset(), do: GenServer.cast(__MODULE__, :reset)
  def remove(user), do: GenServer.cast(__MODULE__, {:remove, user})
  def check(user), do: GenServer.call(__MODULE__, {:get, user})

  @impl true
  def init(_) do
    {:ok, %{}}
  end

  @impl true
  def handle_cast(:reset, _state), do: {:noreply, %{}}
  def handle_cast({:set, user}, state), do: {:noreply, Map.put(state, user, true)}
  def handle_cast({:remove, user}, state), do: {:noreply, Map.drop(state, [user])}

  @impl true
  def handle_call({:get, user}, _from, state) do
    exists? = user in Map.keys(state)
    {:reply, exists?, state}
  end
end
