defmodule Dialogus.State do
  use Supervisor

  @pubsub Module.concat([__MODULE__, "PubSub"])

  def subscribe,
    do: Phoenix.PubSub.subscribe(@pubsub, "#{__MODULE__}")

  def broadcast(payload) when is_tuple(payload) do
    Phoenix.PubSub.broadcast(@pubsub, "#{__MODULE__}", payload)
    payload
  end

  def broadcast(payload, event \\ nil, origin \\ __MODULE__)
      when is_atom(event) and is_atom(origin) do
    if event do
      Phoenix.PubSub.broadcast(@pubsub, "#{__MODULE__}", {origin, event, payload})
    else
      Phoenix.PubSub.broadcast(@pubsub, "#{__MODULE__}", {origin, payload})
    end

    payload
  end

  def start_link(init_arg),
    do: Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)

  @impl true
  def init(_init_arg) do
    children =
      with {:ok, modules} <- :application.get_key(:dialogus, :modules) do
        modules
        |> Enum.filter(&("#{&1}" != "#{__MODULE__}"))
        |> Enum.filter(&String.starts_with?("#{&1}", "#{__MODULE__}."))
        |> Enum.filter(&Keyword.has_key?(&1.__info__(:functions), :start_link))
      end

    Supervisor.init([{Phoenix.PubSub, name: @pubsub} | children],
      strategy: :one_for_one
    )
  end

  defmacro report(payload) do
    quote do
      unquote(__MODULE__).broadcast(unquote(payload), elem(__ENV__.function, 0), __MODULE__)
      send(self(), {__MODULE__, elem(__ENV__.function, 0), unquote(payload)})
      unquote(payload)
    end
  end

  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias unquote(__MODULE__), as: State
      import unquote(__MODULE__), only: [report: 1]

      defp persistence_path do
        filename =
          "#{__MODULE__}"
          |> String.replace_prefix("#{unquote(__MODULE__)}.", "")
          |> String.split(".")
          |> Enum.map(&Macro.underscore/1)
          |> Enum.join("-")

        "_state_persistence/#{filename}.dat"
      end

      defp set_persistence(state \\ nil) do
        payload = state || get()

        with :ok <- File.mkdir_p(Path.dirname(persistence_path())),
             do: File.write(persistence_path(), :erlang.term_to_binary(payload))

        payload
      end

      defp get_persistence do
        case File.read(persistence_path()) do
          {:ok, binary} -> :erlang.binary_to_term(binary)
          {:error, _} -> %{}
        end
      end

      def start_link(args \\ []) do
        state = Map.merge(Keyword.get(args, :state, %{}), get_persistence())

        with {:ok, pid} <-
               GenServer.start_link(__MODULE__, {false, state}, name: __MODULE__) do
          State.broadcast(state, :start_link, __MODULE__)
          {:ok, pid}
        else
          error -> error
        end
      end

      @persist_tick 1000

      def init(state) do
        Process.flag(:trap_exit, true)
        State.subscribe()
        Process.send_after(self(), {:persist, @persist_tick}, @persist_tick)
        {:ok, report(state)}
      end

      def get,
        do: GenServer.call(__MODULE__, :get)

      def get(key),
        do: GenServer.call(__MODULE__, {:get, key})

      def set(state),
        do: GenServer.cast(__MODULE__, {:set, state})

      def set(key, value),
        do: GenServer.cast(__MODULE__, {:set, key, value})

      def unset(key),
        do: GenServer.cast(__MODULE__, {:unset, key})

      def handle_call(:get, _from, {stale, state}),
        do: {:reply, state, {stale, state}}

      def handle_call({:get, key}, _from, {stale, state}),
        do: {:reply, state[key], {stale, state}}

      def handle_cast({:set, new_state}, _old_state),
        do: {:noreply, report({true, new_state})}

      def handle_cast({:unset, key}, {_stale, state}),
        do: {:noreply, report({true, Map.delete(state, key)})}

      def handle_cast({:set, key, nil}, {_stale, state}),
        do: {:noreply, report({true, Map.delete(state, key)})}

      def handle_cast({:set, key, value}, {_stale, state}),
        do: {:noreply, report({true, Map.put(state, key, value)})}

      def handle_info({:EXIT, _pid, _reason}, {true, state}),
        do: {:noreply, {false, set_persistence(state)}}

      def handle_info({:EXIT, _pid, _reason}, {false, state}),
        do: {:noreply, {false, state}}

      def handle_info({:persist, tick}, {true, state}) do
        Process.send_after(self(), {:persist, tick}, tick)
        {:noreply, {false, set_persistence(state)}}
      end

      def handle_info({:persist, tick}, {false, state}) do
        Process.send_after(self(), {:persist, tick}, tick)
        {:noreply, {false, state}}
      end
    end
  end
end
