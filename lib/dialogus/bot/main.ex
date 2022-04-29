defmodule Dialogus.MainBot do
  use Dialogus.Bot

  # This bot will rescue messages where "bot" is nil or missing in payload
  def handle_info(%{event: event, payload: %{"bot" => nil} = payload, topic: topic}, state) do
    handle_info(
      %{event: event, payload: Map.put(payload, "bot", __MODULE__), topic: topic},
      state
    )
  end

  def anwser(%{"text" => "marco"}),
    do: %{"text" => "polo"}

  def anwser(%{"text" => text}),
    do: %{"text" => "echo: #{text}"}

  def anwser(_anything_else),
    do: nil

  # Ignore anything else
  def handle_info(_message, state),
    do: {:noreply, state}
end
