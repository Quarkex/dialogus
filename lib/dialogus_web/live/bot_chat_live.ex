defmodule DialogusWeb.BotChatLive do
  use DialogusWeb, :live_view

  alias DialogusWeb.Endpoint
  alias Dialogus.Presence
  import Dialogus.Bot, only: [topic: 0]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    Endpoint.subscribe("#{topic()}:#{id}")
    Presence.track(self(), topic(), id, %{})

    {:ok,
     assign(socket, %{
       id: id,
       messages: Dialogus.State.Messages.value(id) || []
     })}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <h1>Id: <%= inspect(@id) %></h1>

    <h2>Messages:</h2>
    <ul>
    <%= for message <- @messages do %>
      <li><%= inspect(message) %></li>
    <% end %>
    </ul>

    <div>
      <.form let={f} for={:payload} phx_submit={:question} >
      <%= text_input f, :text %>
      <%= submit gettext("Submit") %>
      </.form>
    </div>
    """
  end

  # Pass the event triggered from the form to a PubSub message.
  def handle_event(
        "question",
        %{"payload" => payload},
        %{assigns: %{id: id}} = socket
      ) do
    Dialogus.Bot.question(id, payload)
    {:noreply, socket}
  end

  # Append questions when they get here from pubsub (for multi-window sync)
  def handle_info(
        %{event: "question", payload: message},
        %{assigns: %{id: id, messages: messages}} = socket
      ) do
    messages = messages ++ [{:question, message}]
    Dialogus.State.Messages.set(id, messages)
    {:noreply, assign(socket, :messages, messages)}
  end

  # Append anwsers when they arrive
  def handle_info(
        %{event: "anwser", payload: message},
        %{assigns: %{id: id, messages: messages}} = socket
      ) do
    messages = messages ++ [{:question, message}]
    Dialogus.State.Messages.set(id, messages)
    {:noreply, assign(socket, :messages, messages)}
  end

  # Ignore anything else
  def handle_info(_message, socket),
    do: {:noreply, socket}
end