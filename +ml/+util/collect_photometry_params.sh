#!/usr/bin/env bash
set -euo pipefail

# --------- USER SETTINGS ----------
PARENT_DIR="/home/noamse/KMT/data/test"   # directory that contains kmt* folders
DEST_DIR="${PARENT_DIR}/all_params_photo_aux"
# ----------------------------------

mkdir -p "$DEST_DIR"

echo "Parent dir : $PARENT_DIR"
echo "Dest dir   : $DEST_DIR"
echo "-----------------------------------"

count=0
missing=0

for d in "$PARENT_DIR"/kmt*/ ; do
  # skip if no match
  [ -d "$d" ] || continue

  src_file="${d}params_photo-aux_WIS-1.json"
  base="$(basename "$d")"  # e.g. kmt160248_18

  if [ -f "$src_file" ]; then
    out_file="${DEST_DIR}/${base}__params_photo-aux_WIS-1.json"
    cp "$src_file" "$out_file"
    echo "Copied: $src_file -> $out_file"
    ((count++))
  else
    echo "Missing: $src_file"
    ((missing++))
  fi
done

echo "-----------------------------------"
echo "Done. Copied $count files. Missing in $missing folders."

