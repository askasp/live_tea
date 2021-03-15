
defmodule ChatMessagesHandler do
    use Commanded.Event.Handler,
    application: LiveTea.App,
    name: __MODULE__


     def init do
         {:ok, _} = ETS.Bag.new(name: :chats, protection: :public, read_concurrency: true)
         :ok
      end

      def handle(%MessageSent{} = event, _metadata) do
          :chats
          |> ETS.Bag.wrap_existing!()
          |> ETS.Bag.add!({event.chat_id, event})
          :ok = Phoenix.PubSub.broadcast(LiveTea.PubSub, "chat:"<>event.chat_id, event)
          :ok
      end

      def get(chat_id) do
          :chats
          |> ETS.Bag.wrap_existing!()
          |> ETS.Bag.match!({chat_id, :"$0"})
          |> Enum.flat_map(fn x -> x end)
      end
    end
