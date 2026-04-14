#!/bin/bash
# preprocess.sh - Auto-convert file formats before agent analysis
# Handles: .xlsx, .xls, .docx, .doc, .pptx -> readable formats
# PDFs are read natively by Claude Code (no conversion needed)
# Runs on SessionStart via hooks and before each generate

PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
DATA_DIR="$PLUGIN_ROOT/data"
CONVERTED=0
SKIPPED=0
WARNINGS=""

if [ ! -d "$DATA_DIR" ]; then
  exit 0
fi

# ── Helper: check if conversion is needed (source newer than target) ──
needs_conversion() {
  local src="$1" dst="$2"
  [ ! -f "$dst" ] || [ "$src" -nt "$dst" ]
}

# ── Excel .xlsx -> CSV (via pandas) ──
convert_xlsx() {
  if ! command -v python3 &> /dev/null; then
    WARNINGS="$WARNINGS\n- python3 not found. Cannot convert .xlsx files."
    return
  fi
  for f in $(find "$DATA_DIR" -name "*.xlsx" 2>/dev/null); do
    csv_file="${f%.xlsx}.csv"
    if needs_conversion "$f" "$csv_file"; then
      python3 -c "
import sys
try:
    import pandas as pd
    xls = pd.ExcelFile('$f')
    if len(xls.sheet_names) == 1:
        df = pd.read_excel('$f')
        df.to_csv('$csv_file', index=False)
    else:
        for sheet in xls.sheet_names:
            df = pd.read_excel('$f', sheet_name=sheet)
            safe_name = sheet.replace(' ', '-').lower()
            sheet_csv = '${f%.xlsx}' + '-' + safe_name + '.csv'
            df.to_csv(sheet_csv, index=False)
    print('OK: $f')
except ImportError:
    print('NEED_PANDAS', file=sys.stderr)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>/tmp/preprocess_err
      if grep -q "NEED_PANDAS" /tmp/preprocess_err 2>/dev/null; then
        WARNINGS="$WARNINGS\n- pandas not installed. Run: pip3 install pandas openpyxl"
        return
      fi
      CONVERTED=$((CONVERTED + 1))
    fi
  done
}

# ── Excel .xls (legacy) -> CSV ──
convert_xls() {
  for f in $(find "$DATA_DIR" -name "*.xls" ! -name "*.xlsx" 2>/dev/null); do
    csv_file="${f%.xls}.csv"
    if needs_conversion "$f" "$csv_file"; then
      if command -v python3 &> /dev/null; then
        python3 -c "
import sys
try:
    import pandas as pd
    df = pd.read_excel('$f')
    df.to_csv('$csv_file', index=False)
    print('OK: $f')
except ImportError:
    print('NEED_XLRD', file=sys.stderr)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>/tmp/preprocess_err
        if grep -q "NEED_XLRD" /tmp/preprocess_err 2>/dev/null; then
          WARNINGS="$WARNINGS\n- xlrd not installed for .xls files. Run: pip3 install xlrd"
        else
          CONVERTED=$((CONVERTED + 1))
        fi
      fi
    fi
  done
}

# ── Word .docx -> text (via pandoc or python-docx) ──
convert_docx() {
  for f in $(find "$DATA_DIR" -name "*.docx" 2>/dev/null); do
    txt_file="${f%.docx}.txt"
    if needs_conversion "$f" "$txt_file"; then
      if command -v pandoc &> /dev/null; then
        pandoc "$f" -t plain -o "$txt_file" 2>/dev/null && CONVERTED=$((CONVERTED + 1))
      elif command -v python3 &> /dev/null; then
        python3 -c "
import sys
try:
    from docx import Document
    doc = Document('$f')
    text = '\n'.join([p.text for p in doc.paragraphs])
    # Also extract tables
    for table in doc.tables:
        for row in table.rows:
            text += '\n' + '\t'.join([cell.text for cell in row.cells])
    with open('$txt_file', 'w') as out:
        out.write(text)
    print('OK: $f')
except ImportError:
    print('NEED_DOCX', file=sys.stderr)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>/tmp/preprocess_err
        if grep -q "NEED_DOCX" /tmp/preprocess_err 2>/dev/null; then
          WARNINGS="$WARNINGS\n- python-docx not installed. Run: pip3 install python-docx (or: brew install pandoc)"
        else
          CONVERTED=$((CONVERTED + 1))
        fi
      else
        WARNINGS="$WARNINGS\n- No .docx converter found. Install pandoc (brew install pandoc) or python-docx (pip3 install python-docx)"
      fi
    fi
  done
}

# ── Word .doc (legacy) -> text (via textutil on macOS or antiword) ──
convert_doc() {
  for f in $(find "$DATA_DIR" -name "*.doc" ! -name "*.docx" 2>/dev/null); do
    txt_file="${f%.doc}.txt"
    if needs_conversion "$f" "$txt_file"; then
      if command -v textutil &> /dev/null; then
        # macOS built-in converter
        textutil -convert txt -output "$txt_file" "$f" 2>/dev/null && CONVERTED=$((CONVERTED + 1))
      elif command -v antiword &> /dev/null; then
        antiword "$f" > "$txt_file" 2>/dev/null && CONVERTED=$((CONVERTED + 1))
      else
        WARNINGS="$WARNINGS\n- Cannot convert .doc files. On macOS textutil should be available. Otherwise: brew install antiword"
      fi
    fi
  done
}

# ── PowerPoint .pptx -> text (via python-pptx) ──
convert_pptx() {
  for f in $(find "$DATA_DIR" -name "*.pptx" 2>/dev/null); do
    txt_file="${f%.pptx}.txt"
    if needs_conversion "$f" "$txt_file"; then
      if command -v python3 &> /dev/null; then
        python3 -c "
import sys
try:
    from pptx import Presentation
    prs = Presentation('$f')
    text = []
    for i, slide in enumerate(prs.slides, 1):
        text.append(f'--- Slide {i} ---')
        for shape in slide.shapes:
            if shape.has_text_frame:
                text.append(shape.text)
            if shape.has_table:
                for row in shape.table.rows:
                    text.append('\t'.join([cell.text for cell in row.cells]))
    with open('$txt_file', 'w') as out:
        out.write('\n'.join(text))
    print('OK: $f')
except ImportError:
    print('NEED_PPTX', file=sys.stderr)
except Exception as e:
    print(f'ERROR: {e}', file=sys.stderr)
" 2>/tmp/preprocess_err
        if grep -q "NEED_PPTX" /tmp/preprocess_err 2>/dev/null; then
          WARNINGS="$WARNINGS\n- python-pptx not installed. Run: pip3 install python-pptx"
        else
          CONVERTED=$((CONVERTED + 1))
        fi
      fi
    fi
  done
}

# ── Run all converters ──
convert_xlsx
convert_xls
convert_docx
convert_doc
convert_pptx

# ── Count PDFs (no conversion needed, just inform) ──
PDF_COUNT=$(find "$DATA_DIR" -name "*.pdf" 2>/dev/null | wc -l | tr -d ' ')

# ── Report ──
if [ "$CONVERTED" -gt 0 ]; then
  echo "Preprocessed: $CONVERTED files converted."
fi
if [ "$PDF_COUNT" -gt 0 ]; then
  echo "Found $PDF_COUNT PDF files (read natively, no conversion needed)."
fi
if [ -n "$WARNINGS" ]; then
  echo ""
  echo "Conversion warnings:"
  echo -e "$WARNINGS"
  echo ""
  echo "Quick install all dependencies:"
  echo "  brew install pandoc"
  echo "  pip3 install pandas openpyxl python-docx python-pptx xlrd"
fi

rm -f /tmp/preprocess_err
exit 0
