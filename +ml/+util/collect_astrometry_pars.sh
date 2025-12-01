#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <PARENT_DIR> [DEST_DIR]"
  echo
  echo "  PARENT_DIR : directory containing kmt* folders"
  echo "  DEST_DIR   : optional (default: <PARENT_DIR>/astrometry_pars)"
  echo
  echo "Example:"
  echo "  $0 /home/noamse/KMT/data/Experiments/Comb_A_v1"
}

# ---- parse args ----
if [ $# -lt 1 ]; then
  usage
  exit 1
fi

PARENT_DIR="$1"
if [ $# -ge 2 ]; then
  DEST_DIR="$2"
else
  DEST_DIR="${PARENT_DIR}/astrometry_pars"
fi

if [ ! -d "$PARENT_DIR" ]; then
  echo "Error: PARENT_DIR does not exist: $PARENT_DIR"
  exit 1
fi

mkdir -p "$DEST_DIR"

FILES=(
  "results_Comb_A_v1.csv"
  "Dchi2_hist_Comb_A_v1.png"
  "correl_Comb_A_v1.png"
  "chi2_3panel_Comb_A_v1.png"
)

echo "Parent dir : $PARENT_DIR"
echo "Dest dir   : $DEST_DIR"
echo "-----------------------------------"

copied=0
missing=0

for d in "$PARENT_DIR"/kmt*/ ; do
  [ -d "$d" ] || continue
  base="$(basename "$d")"  # e.g. kmt160023_42

  for fname in "${FILES[@]}"; do
    src="${d}${fname}"
    if [ -f "$src" ]; then
      out="${DEST_DIR}/${base}__${fname}"
      cp "$src" "$out"
      echo "Copied: $src -> $out"
      copied=$((copied + 1))
    else
      missing=$((missing + 1))
      # uncomment if you want to see missing files:
      # echo "Missing: $src"
    fi
  done
done

echo "-----------------------------------"
echo "Done. Copied $copied files. Missing $missing expected files."
echo "Output in: $DEST_DIR"

