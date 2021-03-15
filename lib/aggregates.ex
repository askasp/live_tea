defmodule Chat do
    defstruct [chat_id: nil, messages: []]

  def execute(%Chat{}, %SendMessage{sender: sender, chat_id: chat_id, content: content}) do
      %MessageSent{sender: sender, chat_id: chat_id, content: content}
  end


  def apply(%Chat{chat_id: nil} = chat, %MessageSent{} = event) do
      %Chat{chat_id: event.chat_id, messages: [event]}
  end

  def apply(%Chat{} = chat, %MessageSent{} = event) do
      %Chat{chat |  messages: [event | chat.messages] |> Enum.reverse() }
  end
end
