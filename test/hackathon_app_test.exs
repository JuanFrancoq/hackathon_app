defmodule HackathonAppTest do
  use ExUnit.Case
  doctest HackathonApp

  test "greets the world" do
    assert HackathonApp.hello() == :world
  end
end
