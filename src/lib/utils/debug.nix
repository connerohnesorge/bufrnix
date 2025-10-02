/* Bufrnix Debug Utilities
   This file provides a set of helper functions for debugging and logging within
   the Bufrnix ecosystem. It is designed to be imported by other Nix files
   and provides utilities for structured logging, command tracing, and
   environment variable-based configuration overrides.

   Features:
   - Configurable verbosity levels (INFO, DEBUG, TRACE).
   - Timestamped logging to either stderr or a specified log file.
   - Tracing of executed commands for easier debugging.
   - Performance timing for commands at the highest verbosity level.
   - Overrides for debug settings via environment variables (`BUFRNIX_DEBUG`, etc.).
   - Enhanced error reporting with stack traces (in Bash).
   
   Type: DebugUtils :: { lib, ... } -> AttrSet
*/
{lib, ...}:
with lib; {
  /* Generates a shell script snippet to check for and apply debug-related
     environment variables. This allows users to override the debug settings
     from their `flake.nix` for a single run without modifying files.
     
     Environment Variables:
     - `BUFRNIX_DEBUG`: If set, enables debug mode (`debug.enable = true`).
     - `BUFRNIX_DEBUG_LEVEL`: Sets the verbosity level (1-3).
     - `BUFRNIX_DEBUG_LOG`: Specifies a path for the log file.
     
     Type: envVarCheck :: String
  */
  envVarCheck = ''
    # Check for environment variables to override static debug settings.
    if [ -n "$BUFRNIX_DEBUG" ]; then
      debug_enable=true
      if [ -n "$BUFRNIX_DEBUG_LEVEL" ]; then
        debug_verbosity=$BUFRNIX_DEBUG_LEVEL
      else
        debug_verbosity=1 # Default to INFO level if only BUFRNIX_DEBUG is set.
      fi
      if [ -n "$BUFRNIX_DEBUG_LOG" ]; then
        debug_logfile="$BUFRNIX_DEBUG_LOG"
      fi
    fi
  '';

  /* Generates a shell command for logging a message if debugging is enabled
     at the specified verbosity level.

     This function is the core of the logging system. It produces a string
     of shell code that will print a timestamped, level-prefixed message
     to either stderr or the configured log file.
     
     Args:
       level (Int): The verbosity level required to print this log (1=INFO, 2=DEBUG, 3=TRACE).
       msg (String): The message to be logged.
       config (AttrSet): The full Bufrnix configuration, used to access debug settings.
     
     Log Levels:
       1 - INFO: General information about major steps.
       2 - DEBUG: Detailed information about execution flow and commands.
       3 - TRACE: Fine-grained details, including performance timing.
     
     Type: log :: Int -> String -> AttrSet -> String
     
     Example:
       log 1 "Starting protoc generation" config
       => (shell code that prints) "2024-01-15 10:30:45 [bufrnix] INFO: Starting protoc generation"
  */
  log = level: msg: config: let
    shouldLog = config.debug.enable && config.debug.verbosity >= level;
    logPrefix = "[bufrnix] ";
    levelPrefix =
      if level == 1
      then "INFO: "
      else if level == 2
      then "DEBUG: "
      else if level == 3
      then "TRACE: "
      else "";
    timestamp = "$(date '+%Y-%m-%d %H:%M:%S')";
    fullMessage = "${timestamp} ${logPrefix}${levelPrefix}${msg}";
  in
    if shouldLog
    then
      # Direct logs to the specified file or fall back to stderr.
      if config.debug.logFile != ""
      then ''
        echo "${fullMessage}" >> ${config.debug.logFile}
      ''
      else ''
        echo "${fullMessage}" >&2
      ''
    else "";

  /* Generates shell code to print a command before it is executed.
  
     This is used for tracing. When the debug verbosity is 2 (DEBUG) or higher,
     this will log the exact command being run, which is invaluable for
     debugging issues with protoc plugins or arguments.
     
     Args:
       cmd (String): The command string that will be executed.
       config (AttrSet): The Bufrnix configuration.
     
     Type: printCommand :: String -> AttrSet -> String
     
     Example:
       printCommand "protoc --go_out=. example.proto" config
       => (shell code that prints) "2024-01-15 10:30:45 [bufrnix] DEBUG: Executing command: \n  protoc --go_out=. example.proto"
  */
  printCommand = cmd: config: let
    shouldPrint = config.debug.enable && config.debug.verbosity >= 2;
    timestamp = "$(date '+%Y-%m-%d %H:%M:%S')";
  in
    if shouldPrint
    then ''
      echo "${timestamp} [bufrnix] DEBUG: Executing command:" >&2
      echo "  ${cmd}" >&2
    ''
    else "";

  /* Wraps a shell command with performance timing instrumentation.
  
     When verbosity is 3 (TRACE), this function generates shell code that
     records the start and end times of a command's execution, calculates the
     duration, and logs the result. It carefully preserves the original command's
     exit status.
     
     Args:
       cmd (String): The command to be timed.
       config (AttrSet): The Bufrnix configuration.
     
     Returns: The original command string if timing is disabled, or the wrapped
              command with timing logic if enabled.
     
     Type: timeCommand :: String -> AttrSet -> String
  */
  timeCommand = cmd: config: let
    shouldTime = config.debug.enable && config.debug.verbosity >= 3;
    timestamp = "$(date '+%Y-%m-%d %H:%M:%S')";
  in
    if shouldTime
    then ''
      echo "${timestamp} [bufrnix] TRACE: Starting command execution" >&2
      echo "  ${cmd}" >&2
      start_time=$(date +%s.%N)
      # Execute command and capture its exit status.
      { ${cmd}; cmd_status=$?; }
      end_time=$(date +%s.%N)
      # Calculate duration using awk for floating point arithmetic.
      duration=$(awk -v end="$end_time" -v start="$start_time" 'BEGIN{print end - start}')
      echo "${timestamp} [bufrnix] TRACE: Command completed in $duration seconds with status $cmd_status" >&2
      if [ $cmd_status -ne 0 ]; then
        echo "${timestamp} [bufrnix] ERROR: Command failed with status $cmd_status" >&2
      fi
      (exit $cmd_status) # Ensure the script's exit status reflects the command's outcome.
    ''
    else cmd;

  /* Generates shell code to report an error and exit.
  
     This provides a standardized way to handle fatal errors. It prints a
     timestamped error message and, if running in Bash, attempts to print a
     simple stack trace to help locate the source of the error.
     
     Args:
       msg (String): The error message to display.
       exitCode (Int): The exit code to use when terminating the script.
     
     Type: enhanceError :: String -> Int -> String
     
     Example:
       enhanceError "protoc compilation failed" 1
       => (shell code that prints an error and then runs) "exit 1"
  */
  enhanceError = msg: exitCode: ''
    echo "$(date '+%Y-%m-%d %H:%M:%S') [bufrnix] ERROR: ${msg}" >&2
    # If using Bash, provide a rudimentary stack trace.
    if [ -n "$BASH_VERSION" ]; then
      echo "Stack trace:" >&2
      for i in $(seq 0 $((\$\{#FUNCNAME[@]} - 1))); do
        echo "  $i: \$\{BASH_SOURCE[$i]}:\$\{BASH_LINENO[$i-1]} \$\{FUNCNAME[$i]}()" >&2
      done
    fi
    exit ${toString exitCode}
  '';

  /* Generates shell script code to initialize all debug-related variables.
  
     This function creates a block of shell code that sets up local shell variables
     (`debug_enable`, `debug_verbosity`, `debug_logfile`) based on the final
     Nix configuration. It also includes the logic to check for environment
     variable overrides and to prepare the log file if one is specified.
     
     Args:
       config (AttrSet): The final, merged Bufrnix configuration.
     
     Returns: A string of shell script code for initialization.
     
     Type: getDebugConfig :: AttrSet -> String
  */
  getDebugConfig = config: ''
    # Initialize shell variables with values from the Nix config.
    debug_enable=${
      if config.debug.enable
      then "true"
      else "false"
    }
    debug_verbosity=${toString config.debug.verbosity}
    debug_logfile="${config.debug.logFile}"

    # Check for and apply any environment variable overrides.
    if [ -n "$BUFRNIX_DEBUG" ]; then
      debug_enable=true
      if [ -n "$BUFRNIX_DEBUG_LEVEL" ]; then
        debug_verbosity=$BUFRNIX_DEBUG_LEVEL
      fi
      if [ -n "$BUFRNIX_DEBUG_LOG" ]; then
        debug_logfile="$BUFRNIX_DEBUG_LOG"
      fi
    fi

    # If logging to a file is enabled, ensure the directory exists.
    if [ -n "$debug_logfile" ] && [ "$debug_enable" = "true" ]; then
      mkdir -p "$(dirname "$debug_logfile")" 2>/dev/null || true
      touch "$debug_logfile" 2>/dev/null || echo "Warning: Could not create log file $debug_logfile" >&2
    fi
  '';
}
