
defmodule InMemoryEventStoreCase do
  use ExUnit.CaseTemplate

  alias Commanded.EventStore.Adapters.InMemory

  setup do
    {:ok, _apps} = Application.ensure_all_started(:live_tea)

    on_exit(fn ->
      :ok = Application.stop(:live_tea)
    end)
  end
end


defmodule LiveTea.ApplicationTest do
      use InMemoryEventStoreCase

     test "disconnected and connected render" do
     Phoenix.PubSub.subscribe(LiveTea.PubSub, "chat:test_id")
     :ok = LiveTea.App.dispatch(%SendMessage{chat_id: "test_id", sender: "Aksel", content: "This is the first message"})
     assert_receive(%MessageSent{chat_id: "test_id", content: "This is the first message", sender: "Aksel"})
     assert ChatMessagesHandler.get("test_id") == [%MessageSent{chat_id: "test_id", content: "This is the first message", sender: "Aksel"}]
  end

end
