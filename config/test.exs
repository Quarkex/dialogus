import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :dialogus, DialogusWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "fdcucHzKxy2snVnIBL7RSqMyoQjQ4QWJ4hD8G/rY+7M0YI+sX25ZZtDtsZE7AWCZ",
  server: false

# In test we don't send emails.
config :dialogus, Dialogus.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
