defmodule ElixirGrpcExample.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_grpc_example,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {ElixirGrpcExample.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:grpc, "~> 0.7.0"},
      {:protobuf, "~> 0.12.0"},
      {:jason, "~> 1.4"},
      {:gun, "~> 2.0"}
    ]
  end
end