defmodule SimpleChatTest do
  use ExUnit.Case

  test "Server starts -> zero connections" do
    assert length(Server.clients()) == 0
  end
end
