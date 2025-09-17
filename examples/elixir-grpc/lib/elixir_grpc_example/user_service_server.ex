defmodule ElixirGrpcExample.UserServiceServer do
  @moduledoc """
  gRPC server implementation for UserService.

  This module will use the generated protobuf modules after running `nix run`.
  """

  # After generation, uncomment:
  # use GRPC.Server, service: Proto.Example.V1.UserService.Service

  # Sample in-memory storage for demonstration
  @initial_users %{
    1 => %{
      id: 1,
      username: "alice",
      email: "alice@example.com",
      full_name: "Alice Smith",
      roles: ["user", "admin"],
      created_at: 1234567890,
      updated_at: 1234567890
    },
    2 => %{
      id: 2,
      username: "bob",
      email: "bob@example.com",
      full_name: "Bob Johnson",
      roles: ["user"],
      created_at: 1234567891,
      updated_at: 1234567891
    }
  }

  def init(_args) do
    {:ok, %{users: @initial_users, next_id: 3}}
  end

  # Uncomment after protobuf generation:

  # @spec create_user(Proto.Example.V1.CreateUserRequest.t(), GRPC.Server.Stream.t()) ::
  #         Proto.Example.V1.CreateUserResponse.t()
  # def create_user(request, _stream) do
  #   # Implementation would go here
  #   user = %Proto.Example.V1.User{
  #     id: 3,
  #     username: request.username,
  #     email: request.email,
  #     full_name: request.full_name,
  #     roles: ["user"],
  #     created_at: System.system_time(:second),
  #     updated_at: System.system_time(:second)
  #   }
  #
  #   %Proto.Example.V1.CreateUserResponse{
  #     user: user,
  #     message: "User created successfully"
  #   }
  # end

  # @spec get_user(Proto.Example.V1.GetUserRequest.t(), GRPC.Server.Stream.t()) ::
  #         Proto.Example.V1.GetUserResponse.t()
  # def get_user(request, _stream) do
  #   case @initial_users[request.id] do
  #     nil ->
  #       raise GRPC.RPCError, status: :not_found, message: "User not found"
  #
  #     user_data ->
  #       user = struct(Proto.Example.V1.User, user_data)
  #       %Proto.Example.V1.GetUserResponse{user: user}
  #   end
  # end

  # @spec list_users(Proto.Example.V1.ListUsersRequest.t(), GRPC.Server.Stream.t()) ::
  #         Proto.Example.V1.ListUsersResponse.t()
  # def list_users(request, _stream) do
  #   users =
  #     @initial_users
  #     |> Map.values()
  #     |> Enum.map(&struct(Proto.Example.V1.User, &1))
  #     |> Enum.take(request.page_size || 10)
  #
  #   %Proto.Example.V1.ListUsersResponse{
  #     users: users,
  #     total: length(users),
  #     page: request.page || 1,
  #     page_size: request.page_size || 10
  #   }
  # end

  # Additional method implementations would go here...
end