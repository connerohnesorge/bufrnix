defmodule ElixirGrpcExample.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the gRPC server
      {GRPC.Server.Supervisor, endpoint: ElixirGrpcExample.Endpoint, port: 50051, start_server: true}
    ]

    opts = [strategy: :one_for_one, name: ElixirGrpcExample.Supervisor]
    Supervisor.start_link(children, opts)
  end
end