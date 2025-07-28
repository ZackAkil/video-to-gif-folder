#!/bin/bash

# This script is designed to be called by an Automator Folder Action.
# It takes a single video file as an argument and converts it to a GIF.

# --- Directory and Command Setup ---
# Get the directory where this script is located
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)

# --- Logging ---
# Create a log file in the script's directory for debugging
LOG_FILE="$SCRIPT_DIR/conversion.log"
exec > "$LOG_FILE" 2>&1
set -x # Echo all commands to the log file for debugging

# --- Configuration ---
# The video file to process is the first argument passed to the script
VIDEO_FILE="$1"

# --- Pre-flight Checks ---
# Exit if no file is provided
if [ -z "$VIDEO_FILE" ]; then
  echo "Error: No video file provided." >&2
  exit 1
fi

# Exit if the provided file doesn't exist
if [ ! -f "$VIDEO_FILE" ]; then
  echo "Error: File '$VIDEO_FILE' not found." >&2
  exit 1
fi



# Define output and processed directories relative to the script's location
OUTPUT_DIR="$SCRIPT_DIR/output"
PROCESSED_DIR="$SCRIPT_DIR/processed"

# Create the directories if they don't already exist
mkdir -p "$OUTPUT_DIR"
mkdir -p "$PROCESSED_DIR"

# --- Configuration ---
# IMPORTANT: Set the full path to your ffmpeg executable.
# Find it by running 'which ffmpeg' in your terminal.
FFMPEG_CMD="/opt/homebrew/bin/ffmpeg" # Default for Homebrew on macOS, adjust if needed

# Check if ffmpeg is executable
if [ ! -x "$FFMPEG_CMD" ]; then
  echo "Error: ffmpeg not found or not executable at $FFMPEG_CMD" >&2
  exit 1
fi

# --- Processing ---
# Extract the filename without the extension
FILENAME=$(basename -- "$VIDEO_FILE")
FILENAME_NO_EXT="${FILENAME%.*}"

echo "Processing file: $FILENAME"

# Run the ffmpeg conversion
"$FFMPEG_CMD" -v error -i "$VIDEO_FILE" -vf "fps=10,scale=320:-1:flags=lanczos" -c:v gif "$OUTPUT_DIR/$FILENAME_NO_EXT.gif"
ffmpeg_exit_code=$?

# --- Post-processing ---
if [ $ffmpeg_exit_code -eq 0 ]; then
  echo "Successfully converted $FILENAME to GIF."
  # Move the original file to the processed directory
  mv "$VIDEO_FILE" "$PROCESSED_DIR/"
  mv_exit_code=$?
  if [ $mv_exit_code -eq 0 ]; then
    echo "Successfully moved original file to $PROCESSED_DIR."
  else
    echo "Error: Failed to move original file. 'mv' exited with code $mv_exit_code." >&2
    exit 1 # Exit with an error code if the move fails
  fi
else
  echo "Error: ffmpeg command failed for $FILENAME with exit code $ffmpeg_exit_code." >&2
fi

exit 0
