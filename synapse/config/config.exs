import Config

config :synapse,
  ejabberd: %{
    host: "prod.ol.epicgames.com",
    ip: "127.0.0.1",
    port: 5280,
    log_level: "debug"
  }


config :ejabberd,
  file: "config/_DO_NOT_TOUCH_ejabberd.yml",
  log_path: 'logs/ejabberd.log'
config :mnesia,
  dir: 'mnesia/'

import_config "#{config_env()}.exs"
