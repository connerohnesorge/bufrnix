# Elixir Basic Example

This example demonstrates basic Protocol Buffer code generation for Elixir using Bufrnix.

## Features

- Basic protobuf message generation
- Nested messages
- Enums
- Maps
- Oneof fields
- Repeated fields

## Prerequisites

- Nix with flakes enabled
- Elixir development environment (provided by the flake)

## Usage

### Generate Protobuf Code

```bash
# Generate the protobuf code
nix run

# Or enter the development shell and generate
nix develop
nix run
```

### Use in Elixir Project

After generation, the protobuf modules will be available in `lib/proto/`. You can use them in your Elixir code:

```elixir
# Create a message
message = %Proto.Example.V1.ExampleMessage{
  id: 1,
  name: "Alice",
  email: "alice@example.com",
  tags: ["elixir", "protobuf"],
  created_at: %Proto.Example.V1.TimestampMessage{
    seconds: System.system_time(:second),
    nanos: 0
  }
}

# Encode to binary
binary = Proto.Example.V1.ExampleMessage.encode(message)

# Decode from binary
decoded = Proto.Example.V1.ExampleMessage.decode(binary)
```

### Run the Example

```bash
# Enter the development shell
nix develop

# Install dependencies
mix deps.get

# Generate protobuf code
nix run

# Run the example
iex -S mix
iex> ExampleUsage.demo()
```

## Generated Files

After running `nix run`, you'll find the generated Elixir code in:

- `lib/proto/example/v1/example.pb.ex` - Generated protobuf modules

## Project Structure

```
.
├── flake.nix           # Nix flake configuration
├── mix.exs             # Elixir project file
├── proto/              # Protocol buffer definitions
│   └── example/v1/
│       └── example.proto
└── lib/                # Elixir source code
    ├── proto/          # Generated protobuf code (after running nix run)
    └── example_usage.ex # Example usage code
```