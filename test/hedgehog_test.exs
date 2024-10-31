defmodule HedgehogTest do
  use ExUnit.Case
  doctest Hedgehog

  test "greets the world" do
    assert Hedgehog.hello() == :world
  end
end
