
# Live Tea - Making a CQRS/DDD/Liveview/Elm-architecture chat app

I considered adding AI to the title to buzz even more, but I refrained.

According to https://mcfunley.com/choose-boring-technology you have a quota on how many new things you can try at once in a project. 
This demo has as much respect for quotas as a russian fishing vessel, and have nothing but non-boring tech.
Naturally, this can make the point of this blag a bit hard to grasp, so to be precise.


My main goal is to:
* Show how phoenix liveview (LV) and CQRS can work together to make fast (really fast), and robust applications.
* Inspire people to see the possibilities of "server-side-rendering"[^1] with websockets

Super opinionated stuff that I wanted to test, but are not essential. They might be good design choices, but also.. they might not :
* Using The Elm Architecture (TEA) (https://guide.elm-lang.org/architecture/) when using phoenix LV
* Using Mnesia for the read model database

When I write actor, I mean an elixir process, which is not the same as a unix process (more lightweight). You could easily have millions of actors on your computer. 


### What I have made
A chat room web app using CQRS and extremly little javascript
[LiveDemo](http://livechat.stadler.no "LiveTea")

[Code](https://github.com/askasp/live_tea)

### How it works

![](https://i.imgur.com/NWaNe3l.png)

1. A browser goes to livechat.stadler.no/some_id and gets html and JS
2. A WS is set up between client and the backend (handled by LV)
3. Liveview spawns an actor with the viewed html as its state (handled by LV)
4. The actor subscribes to to "chat:some_id"
5. A SendMessage Command is sent via WS, dispatched to an aggregate.
6. MessageSent event is written to EventStore
7. An actor subscribing go ES gets the MessageSent event and applies it to the chat state
8. The updated chat is broadcasted to all actors subscribing to "chat:some_id".
9. The html is updated and the diff is sent over WS
10. On the client morphdom applies this html diff and the user sees the new message. (handled by LV)


## Main

### DDD  (Domain driven design)
Domain driven design is about having the code reflect the language you use at work.

The idea is that developers and product/sale people can speak the same language. #halleluja.
This, naturallly, won't work. Tribe language, has been around forever, and DDD won't change that. But, admidettly, its easier to say SendMessage and refer to the message sending function , than the MessageSendingFactoryClassInterfaceImpl.

When doing DDD get a bunch og devs and domain experts in a room and define all the business events. 
In the chat app this is just the MessageSent event. Also, discover domain limitations on when this event can occur. E.g. Has the user sent too many messages the last minute? Is it a duplicate event? etc.. In the chat app I just let everything through.


### CQRS
CQRS is an exceptionally forgettable abbrevation, with the even more bland long name (Command Query Response Segretation).
It means that you should seperate your write from your reads. In practice it becomes event sourcing with extra steps. 

First, write types for all the events discovered. In the chat app it looks like this
##### lib/events.ex
```
defmodule MessageSent do
    @derive Jason.Encoder
    defstruct  [:sender, :chat_id, :content]
end
```

Then do some linguistic flexing and create corresponding commands 
##### lib/commands.ex
```
defmodule SendMessage do
    defstruct  [:sender, :chat_id, :content]
end
```
Now, the domain limitations needs to be validated. In CQRS terminology this is done by the aggregate. 
The aggregate reads all the events in a stream and builds up a state. Based on this state the command is either rejected or an event is created. Which events should belong to the same stream is in this case rather intuitive. All messages in a single chat is in the same stream. 

For most CQRS applications all events are read from scratch on each command attempt. In elixir, for reasons I will come back to, in-memory state is trivial and safe, thus the state can just reside in an actor. 

In this example I use a CQRS package called commanded that does this heavy lifting for us. So we can just focus on the logic. 

##### lib/aggregates.ex
```
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
```

As mentioned, CQRS is about splitting the write from the reads. Now we're done with the write side. On the read side we set up eventhandlers. These can be typically oneoff things like sending an SMS or a thing than can be replayed, like building up a Read Model.

Here, we only have one event handler. And all it does is building up the states of each Chat. That just means to append the messages in a list. 

Now, this state is written to a database. Usually SQL, but I use Mnesia. The reasons are mostly becaus I like things that goes fast. 

*  It har RAM-copies of state so lookups are fast
*  Its bulit into Elixir/erlang

Also, as Elixir has PubSubs integrated in the runtime I broadcast the event to whoever is listening. I could just as well broadcast the entire state. 

#### lib/event_handlers.ex

```e
defmodule ChatReadModel do

    defmodule Model do
        use Memento.Table, attributes: [:chat_id, :sender,:content],
            type: :bag
    end
    use Commanded.Event.Handler,
    application: LiveTea.App,
    name: __MODULE__

      def handle(%MessageSent{} = event, _metadata) do
          :ok = Phoenix.PubSub.broadcast(LiveTea.PubSub, "chat:"<>event.chat_id, event)
          Memento.transaction! fn -> Memento.Query.write(%Model{chat_id: event.chat_id, sender: event.sender,content: event.content}) end
          :ok
      end

      def get(chat_id) do
          Memento.transaction! fn -> Memento.Query.select(Model, {:==, :chat_id, chat_id}) end
      end
    end
    
```


### Phoenix liveview & Elixir

Now, to the bread and butter of this post. This is what I actually want to show.

To get all the terminology straight we'll do as Erlend Loe and make a list

* Erlang, a language made by ericsson in the 90s to handle telecommunications switches.  
* BEAM, the runtime erlang runs on.
* Elixir, a language created in 2011, by Jose Valim, that runs on the BEAM. The syntax is very similar to Ruby making it attractive to a greater (as in larger) community.
* Phoenix, the most popular web framework for Elixir
* Phoenix Liveview, an addition to Phoenix released in v1.5 that allows for server-initiated rerender of web pages.


Read more here:  https://dockyard.com/blog/2018/12/12/phoenix-liveview-interactive-real-time-apps-no-need-to-write-javascript

Phoenix liveview enables "server-side-rendered"[^1] single-page web pages . It does this by the power of a brand-new (not really) technology called websockets.
Liveview sets up a websocket connection between the client and the server. Commands goes from the client, and an updated html is sent back. Morphdom then seemlessly updates the view.

Why isn't this implemented in other backend languages? Well, it's not because a lack of trying.. However websockets are statefull, and most languages have treated state as guy coughing in 2020.

In Elixir/Erlang state is trivial. It was made to handle telecom switches at Ericsson. In fact it's an (unintentional) implementation of the actor model. Each websocket is an totally isolated process (actor) that can only communicate with other actors through message passing. I.e. Share by communicating, don't communicate by sharing (I'm looking at you C++).


My chat app (like any other elixir app) starts inn application.ex
```e
  def start(_type, _args) do
      # Start the Telemetry supervisor
      LiveTeaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveTea.PubSub},
      # Start the Endpoint (http/https)
      LiveTeaWeb.Endpoint,
      LiveTea.App,
      ChatReadModel

```
Each line is a seperate process that can only communicate with the rest by message passsing.
Note, the ChatReadmodel mentioned before. This process starts listening on new events and handle these as they come. The phoneix framework starts in the LiveTeaWeb.Endpoint, which is defined in
lib/live_chat_web/endpoint.ex

This actor listens to http requests and spawns an actor for each, making all requests concurrent. The Endpoint applications handles setting up WS connections and other micmac, usually the file does not have to be edited from what phoenix gives when generating a new app.

At the end of the endpoint file the router is called. And this file must be edited. For the chat app it looks like this 

```
...
  scope "/", LiveTeaWeb do
    pipe_through :browser
    
    # Pokemon route (gotta catch em all)
    live "/*path", PageLive
  end
...
```

This triggers the liveview called PageLive. A liveview must contain at least two functions.
A  ```mount(params, sessiont, socket)``` and a ```render(assigns)```
This is the actor that holds the client state in the socket parameter. The render function returns the HTML.



Whenever the socket is updated, the render function is called anew, and html diffs are sent over the wire. 

Usually, the routing is handled by.. well, the router. But as mentioned before I followed the elm architecture, so I just chucked all that logic into the PageLive module. The reason is that when I first started with MVC I got confused by all the different files, so I spent much time refactoring. TEA was a sweet relief as I could just focus on the logic and as long as I wrote pure functions I could move them later. But tbh. I might have been drinking too much of the cool aid

The code with comments below show how the LiveVew actor is spawned and how the initial render takes place.
```e
  @impl true
  ## Mounts the liveview and assigns the initial socket state
  def mount(_params, session, socket) do
      case session["name"] do
          nil -> {:ok, socket}
          x -> {:ok, assign(socket, name: x)}
          end

  end

  #This function is called on the initial render, and everytime the url is updated.
  #Also when its just mutating the window. parameter.
  # This is my router.
  def handle_params(%{"path" => path}, _uri, socket) do
      case path do
          # Set page to home page
          [] -> {:noreply, assign(socket, page: :home)}
          
          # Subscribe to the chat, read the current chat state, and set the page to
          # the chat_id
          [chat_id] -> Phoenix.PubSub.subscribe(LiveTea.PubSub, "chat:"<>chat_id)

                       messages = ChatReadModel.get(chat_id)
                       {:noreply, assign(socket, page: :chat, chat_id: chat_id, messages: messages)}
      end
     
      # Render html
      def render(assigns) do
      ~L"""
      <%= case @page do %>
        <%=:chat -> %> <%= chat_page(assigns)%>
        <%=_-> %> <%= home_page(assigns)%>
        <% end %>
        
        ....
  """
end
      
      
  end
  
  ```
  
 
 Along with the mount and the render, a Liveview usually also have a```handle_event(event,socket)```  to handle clicks from the clients and/or a ```handle_info(event,socket)``` functions to handle messages from other actors. When the user clicks on the "send" button, handle_event() is called which dispathes the SendMessage command to the chatAggregate. 
After it has gone through the validation process the new state is broadcasted from the readmodel and handle_info() is called. The messages are updated, the render function is called, and the new message is shown to all users on the page. 
```e

  #From the form submit
  def handle_event("send_message", %{"message" => msg}, socket) do
     :ok = LiveTea.App.dispatch(%SendMessage{chat_id: socket.assigns[:chat_id], sender: socket.assigns[:name] , content: msg})
     {:noreply, socket}
  end

  @impl true
  # From the pubsub subscribed to in handle_params
  def handle_info(%MessageSent{} = event, socket) do
      new_sock =assign(socket, messages: socket.assigns[:messages] ++ [event]  )
      {:noreply, push_event(new_sock, "new_message", %{})}
  end

 def chat_page(assigns) do
      ~L"""
      ...
      ...
      <form class="mt-8 w-full flex justify-between mb-24 align-bottom " style="align-items: center" phx-submit="send_message">
        <textarea id="textarea" class="w-3/4 text-gray-300 bg-gray-800 rounded p-2 " type="text" name="message" placeholder="message; Shift-Enter for a newline " autocomplete="off"></textarea>
        <button class="h-8 align-bottom rounded bg-yellow-500 text-gray-900 px-4 " type="submit" phx-disable-with="Sending...">Send </button>
      </form>
      </div>
      """
      end



```

Hope you found this interesting. I, for one, see this as a ecosystem that can do many things you now split into many different technologies (React, reddis, k8s, "mIcRoServices with LambDas"). There is a reason Whatsapp could serve 320 mill users with only 32 engineers, and my bet is that the reason is Elixir/Erlang. 

Bonus: Go go https://livechat.stadler.no/dashboard to see live metrics.  

[^1]: Server-side-initiated is technically more correct, but rendered is what it feels like
