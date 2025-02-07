defmodule SynapseTest do
  use ExUnit.Case
  doctest Synapse

  test "greets the world" do
    assert Synapse.hello() == :world
  end
end
