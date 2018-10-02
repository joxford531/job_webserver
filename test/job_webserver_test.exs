defmodule JobWebserverTest do
  use ExUnit.Case
  doctest JobWebserver

  test "greets the world" do
    assert JobWebserver.hello() == :world
  end
end
