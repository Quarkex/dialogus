defmodule Dialogus.Bot do
  def topic,
    do: "bot_chat"

  def question(id, payload),
    do:
      Phoenix.PubSub.broadcast(Dialogus.PubSub, "#{topic()}:#{id}", %{
        event: "question",
        topic: "#{topic()}:#{id}",
        payload: payload
      })

  defmacro __using__(_opts) do
    quote do
      use GenServer

      alias Dialogus.PubSub
      alias Dialogus.Presence
      import Phoenix.PubSub, only: [subscribe: 2, unsubscribe: 2]
      import Dialogus.Bot, only: [topic: 0]

      def broadcast(topic, event, payload),
        do:
          Phoenix.PubSub.broadcast(PubSub, topic, %{event: event, topic: topic, payload: payload})

      def start_link(args \\ []),
        do: GenServer.start_link(__MODULE__, Keyword.get(args, :state, %{}))

      def init(state) do
        subscribe(PubSub, topic())

        topic()
        |> Presence.list()
        |> Map.keys()
        |> Enum.each(&subscribe(PubSub, "#{topic()}:#{&1}"))

        {:ok, state}
      end

      def handle_info(
            %{event: "presence_diff", payload: %{joins: joins, leaves: leaves}},
            state
          ) do
        joins
        |> Map.keys()
        |> Enum.each(&subscribe(PubSub, "#{topic()}:#{&1}"))

        leaves
        |> Map.keys()
        |> Enum.each(&unsubscribe(PubSub, "#{topic()}:#{&1}"))

        {:noreply, state}
      end

      # Ensure "bot" is always a key of the payload map
      def handle_info(%{event: event, payload: payload, topic: topic}, state)
          when is_map(payload) and not is_map_key(payload, "bot") do
        handle_info(
          %{event: event, payload: Map.put(payload, "bot", nil), topic: topic},
          state
        )
      end

      # Any "question" event with the current bot defined as target inside the
      # payload map will be anwsered by this bot if the function "anwser" is
      # defined. You may use pattern match with the function definition to
      # handle the different messages.
      def handle_info(
            %{event: "question", payload: %{"bot" => __MODULE__} = payload, topic: topic},
            state
          ) do
        if function_exported?(__MODULE__, :anwser, 1),
          do: broadcast(topic, "anwser", apply(__MODULE__, :anwser, [payload]))

        {:noreply, state}
      end
    end
  end
end
