defmodule SendMessage do
    defstruct  [:sender, :chat_id, :content]
end

defmodule CreateChat do
    defstruct  [:chat_id]
end
