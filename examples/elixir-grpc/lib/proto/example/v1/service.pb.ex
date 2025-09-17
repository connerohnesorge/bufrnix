defmodule Example.V1.UserEvent.EventType do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :EVENT_TYPE_UNSPECIFIED, 0
  field :EVENT_TYPE_CREATED, 1
  field :EVENT_TYPE_UPDATED, 2
  field :EVENT_TYPE_DELETED, 3
end

defmodule Example.V1.User do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
  field :username, 2, type: :string
  field :email, 3, type: :string
  field :full_name, 4, type: :string, json_name: "fullName"
  field :roles, 5, repeated: true, type: :string
  field :created_at, 6, type: :int64, json_name: "createdAt"
  field :updated_at, 7, type: :int64, json_name: "updatedAt"
end

defmodule Example.V1.CreateUserRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :username, 1, type: :string
  field :email, 2, type: :string
  field :full_name, 3, type: :string, json_name: "fullName"
  field :password, 4, type: :string
end

defmodule Example.V1.CreateUserResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: Example.V1.User
  field :message, 2, type: :string
end

defmodule Example.V1.GetUserRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
end

defmodule Example.V1.GetUserResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: Example.V1.User
end

defmodule Example.V1.ListUsersRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :page_size, 1, type: :int32, json_name: "pageSize"
  field :page, 2, type: :int32
  field :search, 3, type: :string
end

defmodule Example.V1.ListUsersResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :users, 1, repeated: true, type: Example.V1.User
  field :total, 2, type: :int32
  field :page, 3, type: :int32
  field :page_size, 4, type: :int32, json_name: "pageSize"
end

defmodule Example.V1.UpdateUserRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
  field :email, 2, type: :string
  field :full_name, 3, type: :string, json_name: "fullName"
  field :roles, 4, repeated: true, type: :string
end

defmodule Example.V1.UpdateUserResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user, 1, type: Example.V1.User
  field :message, 2, type: :string
end

defmodule Example.V1.DeleteUserRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
end

defmodule Example.V1.DeleteUserResponse do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :success, 1, type: :bool
  field :message, 2, type: :string
end

defmodule Example.V1.UserEvent do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :event_type, 1, type: Example.V1.UserEvent.EventType, json_name: "eventType", enum: true
  field :user, 2, type: Example.V1.User
  field :timestamp, 3, type: :int64
end

defmodule Example.V1.WatchUsersRequest do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :user_ids, 1, repeated: true, type: :int32, json_name: "userIds"
end

defmodule Example.V1.UserService.Service do
  @moduledoc false

  use GRPC.Service, name: "example.v1.UserService", protoc_gen_elixir_version: "0.15.0"

  rpc :CreateUser, Example.V1.CreateUserRequest, Example.V1.CreateUserResponse

  rpc :GetUser, Example.V1.GetUserRequest, Example.V1.GetUserResponse

  rpc :ListUsers, Example.V1.ListUsersRequest, Example.V1.ListUsersResponse

  rpc :UpdateUser, Example.V1.UpdateUserRequest, Example.V1.UpdateUserResponse

  rpc :DeleteUser, Example.V1.DeleteUserRequest, Example.V1.DeleteUserResponse

  rpc :WatchUsers, Example.V1.WatchUsersRequest, stream(Example.V1.UserEvent)

  rpc :BatchProcess, stream(Example.V1.UpdateUserRequest), stream(Example.V1.UpdateUserResponse)
end

defmodule Example.V1.UserService.Stub do
  @moduledoc false

  use GRPC.Stub, service: Example.V1.UserService.Service
end
