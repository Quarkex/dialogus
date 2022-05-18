defmodule DialogusWeb.DialogLive do
  use DialogusWeb, :live_view

  alias DialogusWeb.Endpoint
  alias Dialogus.Presence
  import Dialogus.DialogHandler, only: [topic: 0]

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    Endpoint.subscribe("#{topic()}:#{id}")
    Presence.track(self(), topic(), id, %{})

    {:ok,
     assign(socket, %{
       id: id,
       messages: Dialogus.State.Messages.get(id) || []
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
      <.form let={f} for={:payload} phx_submit={:utterance} >
      <%= text_input f, :text %>
      <%= submit gettext("Submit") %>
      </.form>
    </div>
    """
  end

  # Pass the event triggered from the form to a PubSub message.
  def handle_event(
        "utterance",
        %{"payload" => payload},
        %{assigns: %{id: id}} = socket
      ) do
    Dialogus.DialogHandler.utterance(id, payload)
    {:noreply, socket}
  end

  # Append utterances when they get here from pubsub (for multi-window sync)
  def handle_info(
        %{event: "utterance", payload: message},
        %{assigns: %{id: id, messages: messages}} = socket
      ) do
    messages = messages ++ [{:utterance, message}]
    Dialogus.State.Messages.set(id, messages)
    {:noreply, assign(socket, :messages, messages)}
  end

  # Append anwsers when they arrive
  def handle_info(
        %{event: "anwser", payload: message},
        %{assigns: %{id: id, messages: messages}} = socket
      ) do
    messages = messages ++ [{:anwser, message}]
    Dialogus.State.Messages.set(id, messages)
    {:noreply, assign(socket, :messages, messages)}
  end

  # Ignore anything else
  def handle_info(_message, socket),
    do: {:noreply, socket}
end
