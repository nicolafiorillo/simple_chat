
import Config

config :simple_chat,
  port: (System.get_env("PORT") || "10000") |> String.to_integer()
