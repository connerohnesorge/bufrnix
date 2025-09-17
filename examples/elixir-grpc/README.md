# Elixir gRPC Example

This example demonstrates gRPC service generation for Elixir using Bufrnix.

## Features

- gRPC service definition and implementation
- Server and client code examples
- Unary RPC methods
- Server streaming RPC
- Bidirectional streaming RPC
- Error handling with gRPC status codes

## Prerequisites

- Nix with flakes enabled
- Elixir development environment (provided by the flake)

## Usage

### Generate gRPC Code

```bash
# Generate the protobuf and gRPC code
nix run

# Or enter the development shell and generate
nix develop
nix run
```

### Run the gRPC Server

```bash
# Enter the development shell
nix develop

# Install dependencies
mix deps.get

# Generate protobuf code
nix run

# Start the gRPC server (runs on port 50051)
iex -S mix
```

### Test with Client

In another terminal:

```bash
# Enter the development shell
nix develop

# Start an IEx session
iex -S mix

# Connect to the server
iex> {:ok, channel} = GRPC.Stub.connect("localhost:50051")

# Create a user (after uncommenting the generated code)
iex> request = %Proto.Example.V1.CreateUserRequest{
...>   username: "john",
...>   email: "john@example.com",
...>   full_name: "John Doe"
...> }
iex> {:ok, response} = Proto.Example.V1.UserService.Stub.create_user(channel, request)

# List users
iex> request = %Proto.Example.V1.ListUsersRequest{page_size: 10}
iex> {:ok, response} = Proto.Example.V1.UserService.Stub.list_users(channel, request)
```

## Generated Files

After running `nix run`, you'll find the generated code in:

- `lib/proto/example/v1/service.pb.ex` - Protobuf message definitions
- `lib/proto/example/v1/service_grpc.pb.ex` - gRPC service and stub definitions

## Project Structure

```
.
├── flake.nix                      # Nix flake configuration
├── mix.exs                        # Elixir project file
├── proto/                         # Protocol buffer definitions
│   └── example/v1/
│       └── service.proto          # gRPC service definition
└── lib/
    ├── proto/                     # Generated code (after nix run)
    └── elixir_grpc_example/
        ├── application.ex         # OTP application
        ├── endpoint.ex            # gRPC endpoint configuration
        ├── user_service_server.ex # Server implementation
        └── client.ex              # Client example code
```

## Implementation Notes

1. After running `nix run`, you'll need to uncomment the code in:
   - `user_service_server.ex` - Server implementation
   - `client.ex` - Client code
   - `endpoint.ex` - Add the service to the endpoint

2. The example includes a simple in-memory storage for demonstration purposes.

3. Error handling is demonstrated using `GRPC.RPCError` for proper gRPC status codes.

## Advanced Features

### Streaming

The example includes streaming RPCs:
- `WatchUsers` - Server streaming for real-time updates
- `BatchProcess` - Bidirectional streaming for batch operations

### Authentication

For production use, you would typically add authentication interceptors:

```elixir
defmodule MyApp.AuthInterceptor do
  use GRPC.Server.Interceptor

  def call(req, stream, next, _opts) do
    with {:ok, _claims} <- verify_token(stream) do
      next.(req, stream)
    else
      _ -> raise GRPC.RPCError, status: :unauthenticated
    end
  end
end
```