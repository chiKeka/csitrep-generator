#!/bin/bash
# archive-data.sh - Archive current data files before generating a new report
# Creates a timestamped snapshot so teams have full history of what was analyzed each period

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="$PLUGIN_ROOT/data"
ARCHIVE_DIR="$DATA_DIR/archive"
DATE=$(date +%Y-%m-%d)
SNAPSHOT="$ARCHIVE_DIR/$DATE"

if [ ! -d "$DATA_DIR" ]; then
  exit 0
fi

# Don't re-archive if today's snapshot already exists
if [ -d "$SNAPSHOT" ]; then
  echo "Archive already exists for $DATE. Skipping."
  exit 0
fi

# Count files to archive (exclude config, archive, and hidden files)
FILE_COUNT=0
for dir in "$DATA_DIR"/*/; do
  dirname=$(basename "$dir")
  [ "$dirname" = "config" ] && continue
  [ "$dirname" = "archive" ] && continue
  count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  FILE_COUNT=$((FILE_COUNT + count))
done

if [ "$FILE_COUNT" -eq 0 ]; then
  echo "No data files to archive."
  exit 0
fi

# Create snapshot directory and copy data folders (excluding config and archive)
mkdir -p "$SNAPSHOT"
for dir in "$DATA_DIR"/*/; do
  dirname=$(basename "$dir")
  [ "$dirname" = "config" ] && continue
  [ "$dirname" = "archive" ] && continue

  # Only copy if folder has files
  count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  if [ "$count" -gt 0 ]; then
    mkdir -p "$SNAPSHOT/$dirname"
    cp "$dir"* "$SNAPSHOT/$dirname/" 2>/dev/null
  fi
done

# Write manifest
echo "Archived: $DATE" > "$SNAPSHOT/manifest.txt"
echo "Files: $FILE_COUNT" >> "$SNAPSHOT/manifest.txt"
echo "" >> "$SNAPSHOT/manifest.txt"
for dir in "$SNAPSHOT"/*/; do
  [ -d "$dir" ] || continue
  dirname=$(basename "$dir")
  count=$(find "$dir" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')
  echo "$dirname: $count files" >> "$SNAPSHOT/manifest.txt"
done

echo "Archived $FILE_COUNT files to data/archive/$DATE/"
exit 0
