defmodule MessageSent do
    @derive Jason.Encoder
    defstruct  [:sender, :chat_id, :content]
end


