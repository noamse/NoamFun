#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <PARENT_DIR> [DEST_DIR]"
  echo
  echo "  PARENT_DIR : directory containing kmt* folders"
  echo "  DEST_DIR   : optional, defaults to <PARENT_DIR>/all_params_photo_aux_variants"
  echo
  echo "Example:"
  echo "  $0 /home/noamse/KMT/data/Experiments/Photometry_v2"
  echo "  $0 /home/noamse/KMT/data/Experiments/Photometry_v2 /tmp/collected_params"
}

# ----- parse args -----
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

PARENT_DIR="$1"

# optional DEST_DIR override
if [ $# -ge 2 ]; then
  DEST_DIR="$2"
else
  DEST_DIR="${PARENT_DIR}/all_params_photo_aux_variants"
fi

# sanity checks
if [ ! -d "$PARENT_DIR" ]; then
  echo "Error: PARENT_DIR does not exist or is not a directory: $PARENT_DIR"
  exit 1
fi

mkdir -p "$DEST_DIR"

# The filenames you want to collect
FILES=(
  "params_photo-aux_WIS-1_std.json"
  "params_photo-aux_WIS-1_plx.json"
  "params_photo-aux_WIS-1_best.json"
  "LL_run_WIS-1.log"
)

echo "Parent dir : $PARENT_DIR"
echo "Dest dir   : $DEST_DIR"
echo "-----------------------------------"

copied=0
missing=0

for d in "$PARENT_DIR"/kmt*/ ; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"  # e.g. kmt160009_02

  for fname in "${FILES[@]}"; do
    src="${d}${fname}"
    if [ -f "$src" ]; then
      out="${DEST_DIR}/${base}__${fname}"
      cp "$src" "$out"
      echo "Copied: $src -> $out"
      copied=$((copied + 1))
    else
      missing=$((missing + 1))
    fi
  done
done

echo "-----------------------------------"
echo "Done. Copied $copied files. Missing $missing expected files."
echo "Output in: $DEST_DIR"
