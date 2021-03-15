
defmodule ChatRouter do
  use Commanded.Commands.Router

  dispatch SendMessage , to: Chat , identity: :chat_id
end
