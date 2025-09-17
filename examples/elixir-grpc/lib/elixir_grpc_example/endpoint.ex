defmodule ElixirGrpcExample.Endpoint do
  use GRPC.Endpoint

  # This will be updated after protobuf generation to include the actual service
  # intercept GRPC.Server.Interceptors.Logger
  # run ElixirGrpcExample.UserService.Server
end