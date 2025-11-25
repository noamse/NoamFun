#!/usr/bin/env bash
set -euo pipefail

# --------- USER SETTINGS ----------
PARENT_DIR="/home/noamse/KMT/data/Experiments/Photometry_v2"   # contains kmt* folders
DEST_DIR="${PARENT_DIR}/all_params_photo_aux_variants"
# ----------------------------------

mkdir -p "$DEST_DIR"

# Exact JSON filenames to collect
JSON_FILES=(
  "params_photo-aux_WIS-1_std.json"
  "params_photo-aux_WIS-1_plx.json"
  "params_photo-aux_WIS-1_best.json"
)

# PNG patterns to collect (globbed within each kmt* dir)
PNG_GLOBS=(
  "lc_aux-phot_WIS-1*.png"
)

echo "Parent dir : $PARENT_DIR"
echo "Dest dir   : $DEST_DIR"
echo "-----------------------------------"

copied=0
missing=0

for d in "$PARENT_DIR"/kmt*/ ; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"  # e.g. kmt160009_02

  # ---- JSONs (exact names) ----
  for fname in "${JSON_FILES[@]}"; do
    src="${d}${fname}"
    if [ -f "$src" ]; then
      out="${DEST_DIR}/${base}__${fname}"
      cp "$src" "$out"
      echo "Copied JSON: $src -> $out"
      copied=$((copied + 1))
    else
      missing=$((missing + 1))
    fi
  done

  # ---- PNGs (glob patterns) ----
  for pat in "${PNG_GLOBS[@]}"; do
    shopt -s nullglob
    for src in "${d}"$pat; do
      fname="$(basename "$src")"
      out="${DEST_DIR}/${base}__${fname}"
      cp "$src" "$out"
      echo "Copied PNG : $src -> $out"
      copied=$((copied + 1))
    done
    shopt -u nullglob
  done

done

echo "-----------------------------------"
echo "Done. Copied $copied files. Missing $missing expected JSON files."
echo "Output in: $DEST_DIR"

