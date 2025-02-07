import Config

config :ssl,
  protocol_version: [:"tlsv1.1", :tlsv1, :"tlsv1.2", :"tlsv1.3"],
  logging_level: :all
