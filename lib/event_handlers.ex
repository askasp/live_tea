
defmodule ChatReadModel do

    defmodule Model do
        use Memento.Table, attributes: [:chat_id, :sender,:content],
            type: :bag
    end


    use Commanded.Event.Handler,
    application: LiveTea.App,
    name: __MODULE__



     def init do
         :ok
      end

      def handle(%MessageSent{} = event, _metadata) do
#x         :ok = Phoenix.PubSub.broadcast(LiveTea.PubSub, "chat:"<> event.chat_id, event)
          Memento.transaction! fn -> Memento.Query.write(%Model{chat_id: event.chat_id, sender: event.sender,content: event.content}) end
          Phoenix.PubSub.broadcast(LiveTea.PubSub, "chat:"<> event.chat_id, get(event.chat_id))
      end

      def get(chat_id) do
          Memento.transaction! fn -> Memento.Query.select(Model, {:==, :chat_id, chat_id}) end
      end
    end
