defmodule Dialogus.State.Persistence do
  use GenServer

  def load(module_name) do
    :dets.open_file(:"state_persistence.dat", [])

    output =
      with [{^module_name, state}] <- :dets.lookup(:"state_persistence.dat", module_name) do
        state
      else
        _ -> %{}
      end

    :dets.close(:"state_persistence.dat")
    output
  end

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, Keyword.get(args, :state, %{}))
  end

  @impl true
  def init(state) do
    Dialogus.State.subscribe()

    Process.send_after(self(), :watcher, 1000)
    {:ok, state}
  end

  @impl true
  def handle_info(:watcher, %{stale: stale_states} = state) do
    :dets.open_file(:"state_persistence.dat", [])

    stale_states
    |> Enum.map(&{&1, apply(&1, :value, [])})
    |> Enum.each(&:dets.insert(:"state_persistence.dat", &1))

    :dets.close(:"state_persistence.dat")

    Process.send_after(self(), :watcher, 1000)
    {:noreply, Map.delete(state, :stale)}
  end

  @impl true
  def handle_info(:watcher, state) do
    Process.send_after(self(), :watcher, 1000)
    {:noreply, state}
  end

  def handle_info(message, state) when is_tuple(message) do
    if tuple_size(message) > 0 do
      module = elem(message, 0)

      if is_atom(module) do
        with ["Dialogus", "State"] <- Module.split(module) |> Enum.take(2) do
          stale_states = (Map.get(state, :stale, []) ++ [module]) |> Enum.dedup()
          {:noreply, Map.put(state, :stale, stale_states)}
        else
          _ ->
            {:noreply, state}
        end
      else
        {:noreply, state}
      end
    else
      {:noreply, state}
    end
  end

  # Ignore unknown messages
  def handle_info(_message, state),
    do: {:noreply, state}
end
