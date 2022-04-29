defmodule Dialogus.State do
  use Supervisor

  def subscribe,
    do: Phoenix.PubSub.subscribe(Dialogus.PubSub, "#{__MODULE__}")

  def broadcast(message) do
    Phoenix.PubSub.broadcast(Dialogus.PubSub, "#{__MODULE__}", message)
    message
  end

  def broadcast(message, action) do
    Phoenix.PubSub.broadcast(Dialogus.PubSub, "#{__MODULE__}", {action, message})
    message
  end

  def start_link(init_arg),
    do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    children = [
      Dialogus.State.Messages,
      Dialogus.State.Stats,
      Dialogus.State.Info,
      Dialogus.State.Persistence
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
