{
  pkgs,
  config,
  lib,
  cfg ? config.languages.proto.copier,
  ...
}:
with lib; let
  # Define output path and options
  outputPaths = if isString cfg.outputPath then [cfg.outputPath] else cfg.outputPath;
  
  # File patterns for inclusion/exclusion
  includePatterns = cfg.includePatterns;
  excludePatterns = cfg.excludePatterns;
  
  # File transformation options
  preserveStructure = cfg.preserveStructure;
  flattenFiles = cfg.flattenFiles;
  filePrefix = cfg.filePrefix;
  fileSuffix = cfg.fileSuffix;
  
  # Generate shell commands for copying files
  generateCopyCommands = outputPath: ''
    echo "Copying proto files to ${outputPath}..."
    mkdir -p "${outputPath}"
    
    # Find proto files for copying
    
    # Find proto files using the same logic as protoc
    proto_files=""
    ${
      # Use the same source directory resolution as mkBufrnix
      if config.protoc.sourceDirectories == [] then ''
        if [ -d "${config.root}" ]; then
          proto_files=$(find "${config.root}" -type f \( ${concatStringsSep " -o " (map (pattern: "-name '${pattern}'") includePatterns)} \))
        fi
      '' else ''
        # Find proto files from specified directories
        ${concatMapStringsSep "\n" (dir: ''
          # Resolve source directory relative to config root
          abs_dir="${config.root}/${dir}"
          if [ -d "$abs_dir" ]; then
            proto_files="$proto_files $(find "$abs_dir" -type f \( ${concatStringsSep " -o " (map (pattern: "-name '${pattern}'") includePatterns)} \))"
          fi
        '') config.protoc.sourceDirectories}
      ''
    }
    
    # Apply exclude patterns and copy files
    for proto_file in $proto_files; do
      [[ -n "$proto_file" ]] || continue
      
      # Check exclude patterns
      should_exclude=false
      ${concatStringsSep "\n" (map (pattern: ''
        if [[ "$proto_file" == ${pattern} ]]; then
          should_exclude=true
        fi
      '') excludePatterns)}
      
      # Skip if excluded
      if [[ "$should_exclude" == "true" ]]; then
        continue
      fi
      [[ -n "$proto_file" ]] || continue
      
      ${if preserveStructure && !flattenFiles then ''
        # Preserve directory structure - calculate relative path from source directory
        rel_path=$(realpath --relative-to="${config.root}" "$proto_file" 2>/dev/null || echo "$proto_file")
        target_dir="${outputPath}/$(dirname "$rel_path")"
        target_file="${outputPath}/$rel_path"
        
        ${optionalString (filePrefix != "") ''
        # Add file prefix
        target_file="${outputPath}/$(dirname "$rel_path")/${filePrefix}$(basename "$rel_path")"
        ''}
        
        ${optionalString (fileSuffix != "") ''
        # Add file suffix (before extension)
        base_name=$(basename "$rel_path" .proto)
        target_file="${outputPath}/$(dirname "$rel_path")/$base_name${fileSuffix}.proto"
        ''}
        
        mkdir -p "$target_dir"
      '' else ''
        # Flatten files (copy all to output root)
        file_name=$(basename "$proto_file")
        target_file="${outputPath}/$file_name"
        
        ${optionalString (filePrefix != "") ''
        # Add file prefix
        target_file="${outputPath}/${filePrefix}$file_name"
        ''}
        
        ${optionalString (fileSuffix != "") ''
        # Add file suffix (before extension)
        base_name=$(basename "$file_name" .proto)
        target_file="${outputPath}/$base_name${fileSuffix}.proto"
        ''}
      ''}
      
      cp "$proto_file" "$target_file"
      echo "Copied: $proto_file -> $target_file"
    done
  '';
in {
  # Runtime dependencies for proto file copying
  runtimeInputs = [
    pkgs.coreutils # for mkdir, cp, find, realpath
    pkgs.findutils # for find
    pkgs.gnugrep   # for grep filtering
  ];

  # No protoc plugins needed for copying
  protocPlugins = [];

  # Initialization hook for proto copier
  initHooks = ''
    # Create output directories for proto copier
    ${concatStringsSep "\n" (map (outputPath: ''
      echo "Initializing proto copier output directory: ${outputPath}"
      mkdir -p "${outputPath}"
    '') outputPaths)}
  '';

  # Code generation hook for proto copier
  generateHooks = ''
    # Proto file copying operations
    echo "Starting proto file copying..."
    
    ${concatStringsSep "\n" (map generateCopyCommands outputPaths)}
    
    echo "Proto file copying completed."
  '';
  
  # Alternative: Run copying in init hooks to avoid protoc dependency
  copyInInitHooks = ''
    # Proto file copying operations (run in init to avoid protoc)
    echo "Starting proto file copying (init phase)..."
    
    ${concatStringsSep "\n" (map generateCopyCommands outputPaths)}
    
    echo "Proto file copying completed (init phase)."
  '';
}