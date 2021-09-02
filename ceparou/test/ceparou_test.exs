defmodule CeparouTest do
  use ExUnit.Case
  doctest Ceparou

  test "greets the world" do
    assert Ceparou.hello() == :world
  end
end
