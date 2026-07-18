defmodule BackendReapiTest do
  use ExUnit.Case
  doctest BackendReapi

  test "greets the world" do
    assert BackendReapi.hello() == :world
  end
end
