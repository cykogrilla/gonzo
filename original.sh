#!/bin/bash
# Task Runner - Run Claude with instructions from a markdown file
# Usage: ./task-runner.sh <task.md> [--tool amp|claude] [max_iterations]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse arguments
TOOL="claude"
MAX_ITERATIONS=10
TASK_FILE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --tool)
      TOOL="$2"
      shift 2
      ;;
    --tool=*)
      TOOL="${1#*=}"
      shift
      ;;
    -*)
      echo "Error: Unknown option '$1'"
      exit 1
      ;;
    *)
      # First positional arg is the task file, rest are max_iterations
      if [[ -z "$TASK_FILE" ]]; then
        TASK_FILE="$1"
      elif [[ "$1" =~ ^[0-9]+$ ]]; then
        MAX_ITERATIONS="$1"
      fi
      shift
      ;;
  esac
done

# Validate task file
if [[ -z "$TASK_FILE" ]]; then
  echo "Usage: $0 <task.md> [--tool amp|claude] [max_iterations]"
  echo ""
  echo "Arguments:"
  echo "  task.md           Path to markdown file containing the task description"
  echo "  --tool            Tool to use: 'amp' or 'claude' (default: claude)"
  echo "  max_iterations    Maximum number of iterations (default: 10)"
  exit 1
fi

if [[ ! -f "$TASK_FILE" ]]; then
  echo "Error: Task file not found: $TASK_FILE"
  exit 1
fi

# Validate tool choice
if [[ "$TOOL" != "amp" && "$TOOL" != "claude" ]]; then
  echo "Error: Invalid tool '$TOOL'. Must be 'amp' or 'claude'."
  exit 1
fi

# Get absolute path to task file
TASK_FILE="$(cd "$(dirname "$TASK_FILE")" && pwd)/$(basename "$TASK_FILE")"

# Generate instructions by substituting the task file path into the template
INSTRUCTIONS=$(sed "s|{{TASK_FILE}}|$TASK_FILE|g" "$SCRIPT_DIR/TASK_RUNNER.md")

echo "Starting Task Runner"
echo "  Task file: $TASK_FILE"
echo "  Tool: $TOOL"
echo "  Max iterations: $MAX_ITERATIONS"

for i in $(seq 1 $MAX_ITERATIONS); do
  echo ""
  echo "==============================================================="
  echo "  Iteration $i of $MAX_ITERATIONS ($TOOL)"
  echo "==============================================================="

  # Run the selected tool with the generated instructions
  if [[ "$TOOL" == "amp" ]]; then
    OUTPUT=$(echo "$INSTRUCTIONS" | amp --dangerously-allow-all 2>&1 | tee /dev/stderr) || true
  else
    OUTPUT=$(echo "$INSTRUCTIONS" | claude --dangerously-skip-permissions --print 2>&1 | tee /dev/stderr) || true
  fi

  # Check for completion signal
  if echo "$OUTPUT" | grep -q "<promise>COMPLETE</promise>"; then
    echo ""
    echo "Task completed!"
    echo "Completed at iteration $i of $MAX_ITERATIONS"
    exit 0
  fi

  echo "Iteration $i complete. Continuing..."
  sleep 2
done

echo ""
echo "Reached max iterations ($MAX_ITERATIONS) without completion signal."
exit 1
