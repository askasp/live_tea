defmodule LiveTeaWeb.PageLive do
  use LiveTeaWeb, :live_view


  @impl true
  def mount(_params, session, socket) do
      case session["name"] do
          nil -> {:ok, socket}
          x -> {:ok, assign(socket, name: x)}
          end

  end

  def handle_params(%{"path" => path}, _uri, socket) do
      IO.inspect(path)
      case path do
          [] -> {:noreply, assign(socket, page: :home)}
          [chat_id] -> Phoenix.PubSub.subscribe(LiveTea.PubSub, "chat:"<>chat_id)

                       messages = ChatReadModel.get(chat_id)
                       {:noreply, assign(socket, page: :chat, chat_id: chat_id, messages: messages)}
      end
  end


  @impl true
  def handle_event("enter_chat", %{"chat_id" => chat_id}, socket) do
      {:noreply, push_patch(socket, to: "/#{chat_id}")}
  end


  #From the form submit
  def handle_event("send_message", %{"message" => msg}, socket) do
     :ok = LiveTea.App.dispatch(%SendMessage{chat_id: socket.assigns[:chat_id], sender: socket.assigns[:name] , content: msg})
     {:noreply, socket}
  end

  #From custom javascropt see send_message hook
  def handle_event("send_message", message, socket) do
     :ok = LiveTea.App.dispatch(%SendMessage{chat_id: socket.assigns[:chat_id], sender: socket.assigns[:name] , content: message})
     {:noreply, socket}
  end


  @impl true
  def handle_info(messages, socket) do
      new_sock =assign(socket, messages: messages)
      {:noreply, push_event(new_sock, "new_message", %{})}
  end


  def render(assigns) do
      ~L"""
      <%= case @page do %>
        <%=:chat -> %> <%= chat_page(assigns)%>
        <%=_-> %> <%= home_page(assigns)%>
        <% end %>
  """
end
def home_page(assigns) do
    ~L"""
    <h1 class="mt-12 text-yellow-500 text-4xl text-center"> Live Chat <h1>

 <form phx-submit="enter_chat" class=" px-8 pt-6 pb-8 mt-24 text-center">
    <div class="mb-4 text-gray-200">
      <input class="text-gray-100 bg-gray-800 shadow appearance-none text-center rounded w-full py-2 px-3 leading-tight focus:outline-none focus:shadow-outline" name="chat_id" id="chat_id" type="text" placeholder="Chat id">
        <button class="bg-yellow-500 text-gray-900 p-3 mt-6 rounded" pe="submit" phx-disable-with="Searching...">Start chatting </button>
    </div>

    </form>

      """
 end

  def chat_page(assigns) do
      ~L"""
      <div class="w-full" id="chatPage" phx-hook="SendMsg" >

      <header class="fixed w-full left-0 top-0  bg-gray-900 mt-0 p-4 pb-2">
    <h1 class="text-yellow-500 text-1xl mb-0 "> Chat id: <%= @chat_id %> </h1>
    <h1 class="text-yellow-500 text-1xl "> Your name: <%= @name %> </h1>
    <hr style="opacity: 0.2">
    </header>

    <div class=" mt-24" phx-hook="Scroll" id="messages">
        <%= for msg <-  @messages do %>
            <div class="bg-gray-800 rounded p-2 text-gray-300 mb-4 mt-0" >
                <h2 class="font-bold " > <%= msg.sender %> </h2>
                    <div style="white-space: pre-line" > <%= msg.content %> </div>
            </div>
        <% end %>
    </div>
    <hr style="opacity: 0.2">

      <form class="mt-8 w-full flex justify-between mb-24 align-bottom " style="align-items: center" phx-submit="send_message">
        <textarea id="textarea" class="w-3/4 text-gray-300 bg-gray-800 rounded p-2 " type="text" name="message" placeholder="message; Shift-Enter for a newline " autocomplete="off"></textarea>
        <button class="h-8 align-bottom rounded bg-yellow-500 text-gray-900 px-4 " type="submit" phx-disable-with="Sending...">Send </button>
      </form>
      </div>

      """
      end





end
