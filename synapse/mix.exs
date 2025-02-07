defmodule Synapse.MixProject do
  use Mix.Project

  def project do
    [
      app: :synapse,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      aliases: aliases()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Synapse.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ejabberd, git: "https://github.com/Tiva-org/ejabberd.git"},
      {:jiffy, "~> 1.1.1", override: true},
      {:httpoison, "~> 1.6.0", override: true},
      {:jason, "~> 1.4"},
      {:expletive, "~> 0.1.0"},
      {:plug, "~> 1.14"},
      {:bandit, "~> 0.6"},
      {:hackney, git: "https://github.com/benoitc/hackney.git", override: true},
      {:fast_xml, git: "https://github.com/AidasPa/fast_xml2.git", override: true}
    ]
  end

  defp aliases do
    [
      "synapse.config": ["run tasks/config.exs --no-start"]
    ]
  end
end
