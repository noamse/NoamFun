#!/usr/bin/env bash
set -u  # no -e so we don't stop on a single missing file
shopt -s nullglob

# Usage:
#   ./collect_params_and_pngs.sh /home/noamse/KMT/data/Experiments/Comb_blend_all
#   ./collect_params_and_pngs.sh EXP_ROOT DEST_DIR
#
# If DEST_DIR is not given, defaults to EXP_ROOT/photometry_outputs

EXP_ROOT="${1:-$(pwd)}"
EXP_ROOT="$(realpath "$EXP_ROOT")"
DEST_DIR="${2:-$EXP_ROOT/photometry_outputs}"
DEST_DIR="$(realpath "$DEST_DIR")"

if [[ ! -d "$EXP_ROOT" ]]; then
  echo "ERROR: EXP_ROOT not a directory: $EXP_ROOT" >&2
  exit 1
fi

mkdir -p "$DEST_DIR"

echo "Parent dir : $EXP_ROOT"
echo "Dest dir   : $DEST_DIR"
echo "-----------------------------------"

copied=0
events_no_files=0

for evdir in "$EXP_ROOT"/kmt??????_??; do
  [[ -d "$evdir" ]] || continue
  event="$(basename "$evdir")"

  out_event_dir="$DEST_DIR/$event"
  mkdir -p "$out_event_dir"

  # find all relevant photometry outputs in event root
  # (maxdepth 1 because your files live there)
  mapfile -t files < <(
   find "$evdir" -maxdepth 1 -type f \( \
      -name "params_photo-aux_*.json" -o \
      -name "lc_aux-phot_*.png" -o \
      -name "aux_fit_diagnostic.png" \
    \) | sort
  )
  
  
  if (( ${#files[@]} == 0 )); then
    echo "[$event] no photometry files found"
    ((events_no_files++))
    continue
  fi

  echo "[$event] copying ${#files[@]} files"
  for f in "${files[@]}"; do
    if cp -u "$f" "$out_event_dir/"; then
      ((copied++))
    else
      echo "  ⚠️ failed to copy: $f"
    fi
  done
done

echo "-----------------------------------"
echo "Done. Copied $copied files."
echo "Events with no matching photometry files: $events_no_files"
echo "Output in: $DEST_DIR"

