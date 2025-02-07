
config = Application.get_env(:synapse, :ejabberd)

defaults = %{
  host: "prod.ol.epicgames.com",
  ip: "127.0.0.1",
  port: 5280
}

map = Map.merge(defaults, config)

template = File.read!("config/ejabberd.yml.template")

result = Enum.reduce(map, template, fn {key, value}, acc ->
  target = "%#{String.upcase(to_string(key))}%"

  String.replace(acc, target, to_string(value))
end)

File.write("config/_DO_NOT_TOUCH_ejabberd.yml", result)

IO.puts("#{IO.ANSI.green()}** Successfully written configuration file.")
IO.puts("#{IO.ANSI.yellow()}** Start with \"iex -S mix\"")
