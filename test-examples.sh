#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Track test results
FAILED_TESTS=()
PASSED_TESTS=()

# Parse command line arguments
VERBOSE=false
if [ "${1:-}" = "-v" ] || [ "${1:-}" = "--verbose" ]; then
    VERBOSE=true
fi

echo -e "${YELLOW}Running bufrnix example tests...${NC}"

# Check we're in the right directory
if [ ! -f "flake.nix" ] || [ ! -d "examples" ]; then
    echo -e "${RED}Error: This script must be run from the bufrnix root directory${NC}"
    echo -e "${RED}Current directory: $(pwd)${NC}"
    exit 1
fi

# Check for nix
if ! command -v nix &> /dev/null; then
    echo -e "${RED}Error: nix command not found. Please install Nix.${NC}"
    exit 1
fi

echo -e "${BLUE}Working directory: $(pwd)${NC}\n"

# Function to test an example
test_example() {
    local example_name=$1
    local example_dir="examples/$example_name"
    shift
    local expected_files=("$@")
    
    echo -e "${YELLOW}Testing $example_name...${NC}"
    
    # Check if example directory exists
    if [ ! -d "$example_dir" ]; then
        echo -e "${RED}✗ Example directory $example_dir does not exist${NC}"
        echo -e "${RED}   Current directory: $(pwd)${NC}"
        echo -e "${RED}   Available examples:${NC}"
        find examples/ -mindepth 1 -maxdepth 1 -type d -printf '     - %f\n' 2>/dev/null
        FAILED_TESTS+=("$example_name: directory not found")
        return 1
    fi
    
    # Clean generated files
    echo "  Cleaning generated files..."
    rm -rf "$example_dir/proto/gen" "$example_dir/gen" 2>/dev/null || true
    
    # Build the example and capture the output path
    echo "  Building..."
    local build_output
    if ! build_output=$(nix build --extra-experimental-features "nix-command flakes" "./$example_dir#default" --no-link --print-out-paths 2>&1); then
        echo -e "${RED}✗ Build failed for $example_name${NC}"
        echo -e "${RED}Build error output:${NC}"
        echo "$build_output" | sed 's/^/    /'
        FAILED_TESTS+=("$example_name: build failed")
        return 1
    fi

    # Extract output path from build output
    local output_path
    output_path=$(echo "$build_output" | tail -n1)
    
    if [ "$VERBOSE" = true ]; then
        echo -e "  ${BLUE}Output path: $output_path${NC}"
        echo -e "  ${BLUE}Generated script content:${NC}"
        cat "$output_path/bin/bufrnix" | grep -E "(protoc|--.*_out=)" | sed 's/^/    /'
    fi
    
    # Run the generated script from the example directory
    echo "  Running code generation..."
    pushd "$example_dir" >/dev/null
    local gen_output
    local gen_exit_code
    gen_output=$("$output_path/bin/bufrnix" 2>&1)
    gen_exit_code=$?
    
    # Filter out known warnings
    local filtered_output=$(echo "$gen_output" | grep -v "warning: directory does not exist" | grep -v "^$")
    
    if [ $gen_exit_code -ne 0 ]; then
        echo -e "${RED}✗ Code generation failed for $example_name (exit code: $gen_exit_code)${NC}"
        echo -e "${RED}Generation error output:${NC}"
        echo "$gen_output" | sed 's/^/    /'
        FAILED_TESTS+=("$example_name: generation failed with exit code $gen_exit_code")
        popd >/dev/null
        return 1
    fi
    
    # Show generation output if not empty
    if [ -n "$filtered_output" ]; then
        echo "$filtered_output" | sed 's/^/    /'
    fi
    
    popd >/dev/null
    
    # Check for expected generated files
    echo "  Checking generated files..."
    local all_found=true
    local missing_files=()
    for expected_file in "${expected_files[@]}"; do
        if [ -f "$example_dir/$expected_file" ]; then
            echo -e "    ${GREEN}✓${NC} Found: $expected_file"
            # Show file size to confirm it's not empty
            local file_size=$(stat -f%z "$example_dir/$expected_file" 2>/dev/null || stat -c%s "$example_dir/$expected_file" 2>/dev/null || echo "unknown")
            echo -e "       Size: $file_size bytes"
        else
            echo -e "    ${RED}✗${NC} Missing: $expected_file"
            missing_files+=("$expected_file")
            all_found=false
        fi
    done
    
    # If files are missing, show what was actually generated
    if [ "$all_found" = false ]; then
        echo -e "  ${YELLOW}Actually generated files:${NC}"
        if [ -d "$example_dir/proto/gen" ]; then
            find "$example_dir/proto/gen" -type f -name "*" 2>/dev/null | sed "s|$example_dir/||" | sed 's/^/    - /' || echo "    (none found)"
        elif [ -d "$example_dir/gen" ]; then
            find "$example_dir/gen" -type f -name "*" 2>/dev/null | sed "s|$example_dir/||" | sed 's/^/    - /' || echo "    (none found)"
        else
            echo "    (no gen directory found)"
        fi
    fi
    
    if [ "$all_found" = true ]; then
        echo -e "${GREEN}✓ $example_name passed${NC}\n"
        PASSED_TESTS+=("$example_name")
        return 0
    else
        echo -e "${RED}✗ $example_name failed - missing expected files${NC}\n"
        FAILED_TESTS+=("$example_name: missing files")
        return 1
    fi
}

# Function to test that specific files do NOT exist (negative testing)
test_files_not_exist() {
    local example_name=$1
    local example_dir="examples/$example_name"
    shift
    local files_that_should_not_exist=("$@")
    
    echo -e "${YELLOW}Testing $example_name (exclusions)...${NC}"
    
    # Check if example directory exists
    if [ ! -d "$example_dir" ]; then
        echo -e "${RED}✗ Example directory $example_dir does not exist${NC}"
        FAILED_TESTS+=("$example_name-exclusions: directory missing")
        return 1
    fi
    
    echo "  Checking excluded files are NOT generated..."
    local all_correctly_excluded=true
    local unexpectedly_found_files=()
    
    for file_that_should_not_exist in "${files_that_should_not_exist[@]}"; do
        if [ -f "$example_dir/$file_that_should_not_exist" ]; then
            echo -e "    ${RED}✗${NC} Found (should be excluded): $file_that_should_not_exist"
            unexpectedly_found_files+=("$file_that_should_not_exist")
            all_correctly_excluded=false
        else
            echo -e "    ${GREEN}✓${NC} Correctly excluded: $file_that_should_not_exist"
        fi
    done
    
    if [ "$all_correctly_excluded" = true ]; then
        echo -e "${GREEN}✓ $example_name exclusions correct${NC}\n"
        PASSED_TESTS+=("$example_name-exclusions")
        return 0
    else
        echo -e "${RED}✗ $example_name exclusions failed - found files that should be excluded${NC}\n"
        FAILED_TESTS+=("$example_name-exclusions: unexpected files found")
        return 1
    fi
}

# Test Go example
test_example "simple-flake" \
    "proto/gen/go/simple/v1/simple.pb.go" \
    "proto/gen/go/simple/v1/simple_grpc.pb.go"

# Test Go flake-parts example
test_example "go-flake-parts" \
    "proto/gen/go/example/v1/service.pb.go" \
    "proto/gen/go/example/v1/service_grpc.pb.go"

# Test Dart example
test_example "dart-example" \
    "proto/gen/dart/example/v1/example.pb.dart" \
    "proto/gen/dart/example/v1/example.pbenum.dart" \
    "proto/gen/dart/example/v1/example.pbgrpc.dart" \
    "proto/gen/dart/example/v1/example.pbjson.dart"

# Test JavaScript example
# JS example uses ES modules with TypeScript target, so it generates .ts files
test_example "js-example" \
    "proto/gen/js/example/v1/example_pb.ts"

# Test JavaScript ES custom outputPath example
# This tests that plugin-specific outputPath (js.es.outputPath) works correctly
test_example "js-es-custom-outputpath" \
    "proto/gen/js/example/v1/example_pb.ts"

# Test PHP Twirp example
test_example "php-twirp" \
    "proto/gen/php/Example/V1/HelloRequest.php" \
    "proto/gen/php/Example/V1/HelloResponse.php" \
    "proto/gen/php/Example/V1/HelloService.php" \
    "proto/gen/php/Example/V1/HelloServiceClient.php" \
    "proto/gen/php/GPBMetadata/Example/V1/Service.php"

# Test Documentation example
test_example "doc-example" \
    "proto/gen/doc/index.html"

# Test Swift example
test_example "swift-example" \
    "proto/gen/swift/example/v1/example.pb.swift"

# Test C# basic example
test_example "csharp-basic" \
    "gen/csharp/Person.cs" \
    "gen/csharp/ExampleProtos.csproj"

# Test C# gRPC example
test_example "csharp-grpc" \
    "gen/csharp/Greeter.cs" \
    "gen/csharp/GreeterGrpc.cs" \
    "gen/csharp/GreeterProtos.csproj"

# Test C# flake-parts example
test_example "csharp-flake-parts" \
    "gen/csharp/ExampleProtos.csproj"

# Test Kotlin basic example
test_example "kotlin-basic" \
    "gen/kotlin/java/com/example/protos/v1/UserProto.java" \
    "gen/kotlin/kotlin/com/example/protos/v1/UserKt.kt" \
    "gen/kotlin/build.gradle.kts"

# Test Kotlin gRPC example
test_example "kotlin-grpc" \
    "gen/kotlin/java/com/example/grpc/v1/GreeterGrpc.java" \
    "gen/kotlin/kotlin/com/example/grpc/v1/GreeterOuterClassGrpcKt.kt" \
    "gen/kotlin/build.gradle.kts"

# Test C protobuf-c example
test_example "c-protobuf-c" \
    "proto/gen/c/protobuf-c/example/v1/example.pb-c.h" \
    "proto/gen/c/protobuf-c/example/v1/example.pb-c.c"

# Test C nanopb example
test_example "c-nanopb" \
    "proto/gen/c/nanopb/example/v1/sensor.pb.h" \
    "proto/gen/c/nanopb/example/v1/sensor.pb.c"

# Test C++ basic example
test_example "cpp-basic" \
    "proto/gen/cpp/example/v1/person.pb.cc" \
    "proto/gen/cpp/example/v1/person.pb.h"

# Test C++ gRPC example
test_example "cpp-grpc" \
    "proto/gen/cpp/example/v1/greeter.pb.cc" \
    "proto/gen/cpp/example/v1/greeter.pb.h" \
    "proto/gen/cpp/example/v1/greeter.grpc.pb.cc" \
    "proto/gen/cpp/example/v1/greeter.grpc.pb.h"

# Test Go advanced example
test_example "go-advanced" \
    "proto/gen/go/example/v1/user.pb.go" \
    "proto/gen/go/example/v1/user_grpc.pb.go" \
    "proto/gen/go/example/v1/user.swagger.json"

# Test Go struct transformer example
test_example "go-struct-transformer" \
    "gen/go/example/v1/product.pb.go" \
    "gen/go/example/v1/transform/product_transformer.go"

# Test JavaScript gRPC-Web example
test_example "js-grpc-web" \
    "proto/gen/js/user_grpc_web_pb.js" \
    "proto/gen/js/chat_grpc_web_pb.js" \
    "proto/gen/js/user_pb.ts" \
    "proto/gen/js/chat_pb.ts"

# Test JavaScript annotations example
test_example "js-annotations" \
    "proto/gen/ts/example/v1/user_service_pb.ts" \
    "proto/gen/ts/example/v1/user_service_pb.js" \
    "proto/gen/ts/google/api/annotations_pb.ts" \
    "proto/gen/ts/google/api/annotations_pb.js" \
    "proto/gen/ts/google/api/http_pb.ts" \
    "proto/gen/ts/google/api/http_pb.js"

# Test JavaScript protovalidate example
test_example "js-protovalidate" \
    "proto/gen/js/example/v1/user_pb.ts"

# Test Multi-language per-files example - POSITIVE tests (files that SHOULD exist)
test_example "multilang-per-files" \
    "backend/generated/go/common/v1/types.pb.go" \
    "backend/generated/go/common/v1/status.pb.go" \
    "backend/generated/go/internal/v1/user_service.pb.go" \
    "backend/generated/go/internal/v1/user_service_grpc.pb.go" \
    "backend/generated/go/internal/v1/admin_service.pb.go" \
    "backend/generated/go/internal/v1/admin_service_grpc.pb.go" \
    "frontend/src/proto/generated/common/v1/types_pb.ts" \
    "frontend/src/proto/generated/common/v1/status_pb.ts" \
    "frontend/src/proto/generated/api/v1/user_api_pb.ts" \
    "frontend/src/proto/generated/api/v1/auth_api_pb.ts" \
    "frontend/src/proto/generated/google/api/annotations_pb.ts" \
    "frontend/src/proto/generated/google/api/http_pb.ts"

# Test Multi-language per-files example - NEGATIVE tests (files that should NOT exist)
test_files_not_exist "multilang-per-files" \
    "backend/generated/go/google/api/annotations.pb.go" \
    "backend/generated/go/google/api/http.pb.go" \
    "backend/generated/go/api/v1/user_api.pb.go" \
    "backend/generated/go/api/v1/auth_api.pb.go" \
    "frontend/src/proto/generated/internal/v1/user_service_pb.ts" \
    "frontend/src/proto/generated/internal/v1/admin_service_pb.ts"

# Test TypeScript flake-parts example
test_example "ts-flake-parts" \
    "gen/js/example/v1/user_pb.ts"

# Test Python flake-parts example
test_example "python-flake-parts" \
    "proto/gen/python/greeter_pb2.py" \
    "proto/gen/python/greeter_pb2_grpc.py"

# Test PHP gRPC RoadRunner example
test_example "php-grpc-roadrunner" \
    "gen/php/Example/V1/GreeterServiceClient.php" \
    "gen/php/Example/V1/HelloRequest.php" \
    "gen/php/Example/V1/HelloResponse.php"

# Test Python basic example
test_example "python-basic" \
    "proto/gen/python/basic_pb2.py"

# Test Python betterproto example
test_example "python-betterproto" \
    "proto/gen/python/modern/__init__.py"

# Test Python example
test_example "python-example" \
    "proto/gen/python/example/v1/example_pb2.py" \
    "proto/gen/python/example/v1/example_pb2_grpc.py"

# Test Python gRPC example
test_example "python-grpc" \
    "proto/gen/python/greeter_pb2.py" \
    "proto/gen/python/greeter_pb2_grpc.py"

# Test Python typed example
test_example "python-typed" \
    "proto/gen/python/typed/v1/typed_pb2.py" \
    "proto/gen/python/typed/v1/typed_pb2.pyi" \
    "proto/gen/python/typed/v1/typed_pb2_grpc.py"

# Test SVG example
test_example "svg-example" \
    "proto/gen/svg/example/v1/example.svg" \
    "proto/gen/doc/index.html"

# # Test Scala basic example
# test_example "scala-basic" \
#     "gen/scala/com/example/protobuf/v1/person/Person.scala"
#
# Test Java basic example
test_example "java-basic" \
    "gen/java/com/example/protos/v1/Person.java" \
    "gen/java/com/example/protos/v1/PersonOrBuilder.java" \
    "gen/java/com/example/protos/v1/PersonProto.java" \
    "gen/java/com/example/protos/v1/AddressBook.java" \
    "gen/java/com/example/protos/v1/AddressBookOrBuilder.java" \
    "gen/java/build.gradle" \
    "gen/java/pom.xml"

# Test Go multiple outputs example  
test_example "go-multiple-outputs" \
    "gen/go/orders/v1/order.pb.go" \
    "gen/go/payments/v1/payment.pb.go" \
    "services/order/proto/orders/v1/order.pb.go" \
    "services/payment/proto/payments/v1/payment.pb.go" \
    "services/shared/proto/orders/v1/order.pb.go" \
    "pkg/common/proto/orders/v1/order.pb.go"

# Test Java gRPC example
test_example "java-grpc" \
    "gen/java/com/example/grpc/v1/HelloRequest.java" \
    "gen/java/com/example/grpc/v1/HelloRequestOrBuilder.java" \
    "gen/java/com/example/grpc/v1/HelloResponse.java" \
    "gen/java/com/example/grpc/v1/HelloResponseOrBuilder.java" \
    "gen/java/com/example/grpc/v1/GreeterProto.java" \
    "gen/java/com/example/grpc/v1/GreeterServiceGrpc.java" \
    "gen/java/build.gradle" \
    "gen/java/pom.xml"

# Test Java protovalidate example  
test_example "java-protovalidate" \
    "gen/java/com/example/protos/v1/User.java" \
    "gen/java/com/example/protos/v1/UserProfile.java" \
    "gen/java/com/example/protos/v1/CreateUserRequest.java" \
    "gen/java/com/example/protos/v1/CreateUserResponse.java" \
    "gen/java/com/example/protos/v1/ValidateUserRequest.java" \
    "gen/java/com/example/protos/v1/ValidateUserResponse.java" \
    "gen/java/build.gradle" \
    "gen/java/pom.xml"

# Test Elixir examples
test_example "elixir-basic" \
    "lib/proto/example/v1/example.pb.ex" \
    "lib/proto/.formatter.exs"

test_example "elixir-grpc" \
    "lib/proto/example/v1/service.pb.ex" \
    "lib/proto/.formatter.exs"

# Summary
echo -e "\n${YELLOW}Test Summary:${NC}"
echo -e "${GREEN}Passed: ${#PASSED_TESTS[@]}${NC}"
echo -e "${RED}Failed: ${#FAILED_TESTS[@]}${NC}"

if [ ${#PASSED_TESTS[@]} -gt 0 ]; then
    echo -e "\n${GREEN}Passed tests:${NC}"
    for test in "${PASSED_TESTS[@]}"; do
        echo -e "  ${GREEN}✓${NC} $test"
    done
fi

if [ ${#FAILED_TESTS[@]} -gt 0 ]; then
    echo -e "\n${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "  ${RED}✗${NC} $test"
    done
    echo -e "\n${RED}Some tests failed!${NC}"
    exit 1
else
    echo -e "\n${GREEN}All tests passed!${NC}"
    exit 0
fi
