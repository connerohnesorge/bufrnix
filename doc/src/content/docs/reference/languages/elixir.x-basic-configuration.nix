languages.elixir = {
  enable = true;
  outputPath = "lib/proto";
  namespace = "MyApp.Proto";
  options = [];

  # Enable gRPC service generation
  grpc = {
    enable = true;
    options = [];
  };

  # Enable validation support
  validate = {
    enable = true;
    options = [];
  };

  # Compile specific proto files for Elixir
  files = [
    "./proto/services/v1/user_service.proto"
    "./proto/messages/v1/common.proto"
  ];

  # Additional proto files beyond the global list
  additionalFiles = [
    "./proto/internal/v1/admin.proto"
  ];
};