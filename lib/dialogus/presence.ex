defmodule Dialogus.Presence do
  use Phoenix.Presence,
    otp_app: :dialogus,
    pubsub_server: Dialogus.PubSub
end
