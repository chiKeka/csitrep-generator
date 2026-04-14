#!/bin/bash
# Load sample data for testing the SitRep Generator plugin
# Usage: ./sample-data/load-sample.sh [project-type]
# Example: ./sample-data/load-sample.sh construction

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
PROJECT_TYPE="${1:-construction}"
SAMPLE_DIR="$PLUGIN_ROOT/sample-data/$PROJECT_TYPE"
DATA_DIR="$PLUGIN_ROOT/data"

if [ ! -d "$SAMPLE_DIR" ]; then
  echo "No sample data found for project type: $PROJECT_TYPE"
  echo "Available types:"
  ls -1 "$PLUGIN_ROOT/sample-data/" | grep -v "load-sample.sh"
  exit 1
fi

echo "Loading sample data for: $PROJECT_TYPE"

# Copy config
if [ -f "$SAMPLE_DIR/config/project-info.json" ]; then
  mkdir -p "$DATA_DIR/config"
  cp "$SAMPLE_DIR/config/project-info.json" "$DATA_DIR/config/project-info.json"
  echo "  Loaded project config"
fi

# Copy all data folders
for folder in "$SAMPLE_DIR"/*/; do
  folder_name=$(basename "$folder")
  [ "$folder_name" = "config" ] && continue

  mkdir -p "$DATA_DIR/$folder_name"
  cp "$folder"* "$DATA_DIR/$folder_name/" 2>/dev/null
  file_count=$(ls -1 "$DATA_DIR/$folder_name/" 2>/dev/null | grep -v README.md | wc -l | tr -d ' ')
  echo "  Loaded $file_count files into data/$folder_name/"
done

echo ""
echo "Sample data loaded. Run /csitrep-generator:generate to test."
