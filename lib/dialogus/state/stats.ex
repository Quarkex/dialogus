defmodule Dialogus.State.Stats do
  use Agent

  alias Dialogus.State.Persistence

  import Dialogus.State, only: [broadcast: 1]

  def start_link(args \\ []) do
    output =
      Agent.start_link(
        fn -> Keyword.get(args, :initial_value) || Persistence.load(__MODULE__) end,
        name: __MODULE__
      )

    broadcast({__MODULE__, elem(__ENV__.function, 0), Agent.get(__MODULE__, & &1)})
    output
  end

  @impl true
  def init(state \\ %{}) do
    Dialogus.State.subscribe()

    {:ok, state}
  end

  # Ignore unknown messages
  def handle_info(_message, state),
    do: {:noreply, state}

  def value,
    do: Agent.get(__MODULE__, & &1)

  def value(key),
    do: Agent.get(__MODULE__, &Map.get(&1, key))

  def increment(key) do
    broadcast({__MODULE__, elem(__ENV__.function, 0), key})
    Agent.update(__MODULE__, &Map.put(&1, key, Map.get(&1, key, 0) + 1))
  end

  def decrement(key) do
    broadcast({__MODULE__, elem(__ENV__.function, 0), key})
    Agent.update(__MODULE__, &Map.put(&1, key, Map.get(&1, key, 0) - 1))
  end

  def set(key, value) do
    broadcast({__MODULE__, elem(__ENV__.function, 0), key, value})
    Agent.update(__MODULE__, &Map.put(&1, key, value))
  end

  def unset(key) do
    broadcast({__MODULE__, elem(__ENV__.function, 0), key})
    Agent.update(__MODULE__, &Map.delete(&1, key))
  end
end
