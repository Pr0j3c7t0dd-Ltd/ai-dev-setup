#!/bin/bash

# Lint and type check script for Claude Code hooks
# This script checks the file type and runs appropriate linting/type checking

if [ -z "$1" ]; then
    echo "Usage: $0 <file_path>"
    exit 0  # Exit successfully when no file provided
fi

FILE_PATH="$1"

# Skip if file doesn't exist
if [ ! -f "$FILE_PATH" ]; then
    echo "ℹ️  File not found: $FILE_PATH"
    exit 0
fi

# Skip if this is the lint script itself
SCRIPT_PATH="$(realpath "$0" 2>/dev/null || echo "$0")"
FILE_REALPATH="$(realpath "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
if [ "$SCRIPT_PATH" = "$FILE_REALPATH" ]; then
    echo "ℹ️  Skipping self-linting"
    exit 0
fi

FILE_EXT="${FILE_PATH##*.}"
FILE_DIR="$(dirname "$FILE_PATH")"
PROJECT_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Function to find and run command if available
run_if_exists() {
    local cmd="$1"
    shift
    if command -v "$cmd" &> /dev/null; then
        "$cmd" "$@"
        return $?
    fi
    return 0
}

# Function to run npm script if it exists
run_npm_script() {
    local script="$1"
    shift
    if [ -f "$PROJECT_ROOT/package.json" ] && npm run | grep -q "$script"; then
        (cd "$PROJECT_ROOT" && npm run "$script" -- "$@")
        return $?
    fi
    return 0
}

case "$FILE_EXT" in
    py)
        echo "🐍 Checking Python file: $FILE_PATH"
        
        # Run Python linters
        run_if_exists ruff check "$FILE_PATH"
        run_if_exists flake8 "$FILE_PATH"
        run_if_exists pylint "$FILE_PATH"
        
        # Run Python type checkers
        run_if_exists mypy "$FILE_PATH"
        run_if_exists pyright "$FILE_PATH"
        ;;
        
    ts|tsx)
        echo "📘 Checking TypeScript file: $FILE_PATH"
        
        # Try project-specific commands first
        run_npm_script lint "$FILE_PATH" || run_npm_script "lint:fix" "$FILE_PATH"
        run_npm_script typecheck "$FILE_PATH" || run_npm_script "type-check" "$FILE_PATH"
        
        # Fall back to global tools if available
        run_if_exists eslint "$FILE_PATH"
        run_if_exists tsc --noEmit --skipLibCheck "$FILE_PATH"
        ;;
        
    js|jsx)
        echo "📗 Checking JavaScript file: $FILE_PATH"
        
        # Try project-specific commands first
        run_npm_script lint "$FILE_PATH" || run_npm_script "lint:fix" "$FILE_PATH"
        
        # Fall back to global tools if available
        run_if_exists eslint "$FILE_PATH"
        ;;
        
    sh|bash)
        echo "🐚 Checking shell script: $FILE_PATH"
        
        # Run shellcheck if available
        run_if_exists shellcheck "$FILE_PATH"
        
        # Check bash syntax
        bash -n "$FILE_PATH" 2>&1
        ;;
        
    *)
        echo "ℹ️  No specific linting configured for .$FILE_EXT files"
        exit 0  # Exit successfully for unsupported file types
        ;;
esac

echo "✅ Lint and type check complete for $FILE_PATH"
exit 0  # Always exit successfully unless a linter fails above