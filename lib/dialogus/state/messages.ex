defmodule Dialogus.State.Messages do
  use Dialogus.State

  # Ignore unknown messages
  def handle_info(_message, state),
    do: {:noreply, state}
end
