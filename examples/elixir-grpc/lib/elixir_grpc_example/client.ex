defmodule ElixirGrpcExample.Client do
  @moduledoc """
  gRPC client for testing the UserService.

  This module demonstrates how to use the generated gRPC client code.
  """

  def connect(host \\ "localhost", port \\ 50051) do
    # After generation, uncomment:
    # {:ok, channel} = GRPC.Stub.connect("#{host}:#{port}")
    # channel
    {:ok, "Client will connect after protobuf generation"}
  end

  def create_user(channel, username, email, full_name) do
    # After generation, uncomment:
    # request = %Proto.Example.V1.CreateUserRequest{
    #   username: username,
    #   email: email,
    #   full_name: full_name,
    #   password: "temporary"
    # }
    # Proto.Example.V1.UserService.Stub.create_user(channel, request)
    {:ok, "create_user will work after protobuf generation"}
  end

  def get_user(channel, id) do
    # After generation, uncomment:
    # request = %Proto.Example.V1.GetUserRequest{id: id}
    # Proto.Example.V1.UserService.Stub.get_user(channel, request)
    {:ok, "get_user will work after protobuf generation"}
  end

  def list_users(channel, page_size \\ 10) do
    # After generation, uncomment:
    # request = %Proto.Example.V1.ListUsersRequest{
    #   page_size: page_size,
    #   page: 1
    # }
    # Proto.Example.V1.UserService.Stub.list_users(channel, request)
    {:ok, "list_users will work after protobuf generation"}
  end

  def demo do
    IO.puts("Elixir gRPC Client Demo")
    IO.puts("========================")
    IO.puts("")
    IO.puts("After running 'nix run' to generate the protobuf code:")
    IO.puts("  1. Uncomment the code in this module")
    IO.puts("  2. Start the server: iex -S mix")
    IO.puts("  3. In another terminal, connect a client:")
    IO.puts("")
    IO.puts("     iex> {:ok, channel} = ElixirGrpcExample.Client.connect()")
    IO.puts("     iex> ElixirGrpcExample.Client.list_users(channel)")
    IO.puts("")
  end
end