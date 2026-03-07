#!/bin/bash
# preprocess.sh - Auto-convert unsupported file formats before agent analysis
# Runs on SessionStart via hooks/hooks.json

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="$PLUGIN_ROOT/data"
CONVERTED=0

# Check if data directory exists
if [ ! -d "$DATA_DIR" ]; then
  echo "Data directory not found at $DATA_DIR"
  exit 0
fi

# Convert Excel (.xlsx) to CSV
if command -v python3 &> /dev/null; then
  for f in $(find "$DATA_DIR" -name "*.xlsx" 2>/dev/null); do
    csv_file="${f%.xlsx}.csv"
    if [ ! -f "$csv_file" ] || [ "$f" -nt "$csv_file" ]; then
      python3 -c "
import sys
try:
    import pandas as pd
    df = pd.read_excel('$f')
    df.to_csv('$csv_file', index=False)
    print('Converted: $f -> $csv_file')
except ImportError:
    print('Warning: pandas not installed. Cannot convert Excel files.', file=sys.stderr)
    print('Install with: pip3 install pandas openpyxl', file=sys.stderr)
except Exception as e:
    print(f'Error converting $f: {e}', file=sys.stderr)
" 2>&1
      CONVERTED=$((CONVERTED + 1))
    fi
  done
fi

# Convert Word (.docx) to text
if command -v pandoc &> /dev/null; then
  for f in $(find "$DATA_DIR" -name "*.docx" 2>/dev/null); do
    txt_file="${f%.docx}.txt"
    if [ ! -f "$txt_file" ] || [ "$f" -nt "$txt_file" ]; then
      pandoc "$f" -t plain -o "$txt_file" 2>/dev/null
      if [ $? -eq 0 ]; then
        echo "Converted: $f -> $txt_file"
        CONVERTED=$((CONVERTED + 1))
      else
        echo "Warning: Failed to convert $f" >&2
      fi
    fi
  done
else
  # Check if any docx files exist that need conversion
  DOCX_COUNT=$(find "$DATA_DIR" -name "*.docx" 2>/dev/null | wc -l)
  if [ "$DOCX_COUNT" -gt 0 ]; then
    echo "Warning: pandoc not installed. Cannot convert $DOCX_COUNT .docx files." >&2
    echo "Install with: brew install pandoc" >&2
  fi
fi

if [ "$CONVERTED" -gt 0 ]; then
  echo "Preprocessing complete: $CONVERTED files converted."
else
  echo "Preprocessing complete: no conversions needed."
fi

exit 0
