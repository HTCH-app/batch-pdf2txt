#!/bin/bash

# Set input directory from first argument, or default to current directory
INPUT_DIR="${1:-.}"

# Validate input directory exists
if [ ! -d "$INPUT_DIR" ]; then
  echo "❌ Error: '$INPUT_DIR' is not a valid directory."
  exit 1
fi

# Create output directory relative to input
mkdir -p "$INPUT_DIR/output"

# Spinner function to show progress per file (optional, not currently used)
spinner() {
  local pid=$1
  local delay=0.1
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c] Processing..." "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\r"
  done
}

# Process a single PDF
process_pdf() {
  local file="$1"
  local filename=$(basename "$file" .pdf)
  echo "➡️  Starting: $filename.pdf"

  if pdf2txt.py -o "$INPUT_DIR/output/${filename}.txt" -t text -Y normal "$file"; then
    echo "✅ Done: $filename.pdf"
  else
    echo "❌ Failed: $filename.pdf (possibly encrypted)" >> "$INPUT_DIR/failed_pdfs.log"
  fi
}

export -f process_pdf
export INPUT_DIR

# Loop through PDFs in input directory and run in parallel (max 4 jobs)
MAX_JOBS=4
JOB_COUNT=0

find "$INPUT_DIR" -maxdepth 1 -name '*.pdf' | while read -r pdf; do
  ((JOB_COUNT++))
  (process_pdf "$pdf") &

  if (( JOB_COUNT % MAX_JOBS == 0 )); then
    wait
  fi
done

wait
echo "🎉 All PDFs processed."
