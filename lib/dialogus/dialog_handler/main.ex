defmodule Dialogus.MainDialogHandler do
  use Dialogus.DialogHandler

  # This dialog handler will rescue messages where "dialog_handler" is nil or missing in payload
  def handle_info(%{event: event, payload: %{"dialog_handler" => nil} = payload, topic: topic}, state) do
    handle_info(
      %{event: event, payload: Map.put(payload, "dialog_handler", __MODULE__), topic: topic},
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
