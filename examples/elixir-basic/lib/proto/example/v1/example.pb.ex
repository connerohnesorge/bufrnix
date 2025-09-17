defmodule Example.V1.Status do
  @moduledoc false

  use Protobuf, enum: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :STATUS_UNSPECIFIED, 0
  field :STATUS_ACTIVE, 1
  field :STATUS_INACTIVE, 2
  field :STATUS_PENDING, 3
  field :STATUS_ARCHIVED, 4
end

defmodule Example.V1.ExampleMessage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
  field :name, 2, type: :string
  field :email, 3, type: :string
  field :tags, 4, repeated: true, type: :string
  field :description, 5, proto3_optional: true, type: :string
  field :created_at, 6, type: Example.V1.TimestampMessage, json_name: "createdAt"
end

defmodule Example.V1.TimestampMessage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :seconds, 1, type: :int64
  field :nanos, 2, type: :int32
end

defmodule Example.V1.StatusMessage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :id, 1, type: :int32
  field :status, 2, type: Example.V1.Status, enum: true
  field :message, 3, type: :string
end

defmodule Example.V1.ConfigMessage.SettingsEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :string
  field :value, 2, type: :string
end

defmodule Example.V1.ConfigMessage.ExamplesByIdEntry do
  @moduledoc false

  use Protobuf, map: true, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :key, 1, type: :int32
  field :value, 2, type: Example.V1.ExampleMessage
end

defmodule Example.V1.ConfigMessage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  field :settings, 1, repeated: true, type: Example.V1.ConfigMessage.SettingsEntry, map: true

  field :examples_by_id, 2,
    repeated: true,
    type: Example.V1.ConfigMessage.ExamplesByIdEntry,
    json_name: "examplesById",
    map: true
end

defmodule Example.V1.NotificationMessage do
  @moduledoc false

  use Protobuf, protoc_gen_elixir_version: "0.15.0", syntax: :proto3

  oneof :notification, 0

  field :email, 1, type: :string, oneof: 0
  field :sms, 2, type: :string, oneof: 0
  field :push, 3, type: :string, oneof: 0
  field :content, 4, type: :string
  field :sent_at, 5, type: Example.V1.TimestampMessage, json_name: "sentAt"
end
