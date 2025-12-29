#!/usr/bin/env bash
set -u  # no -e, keep going if something is missing
shopt -s nullglob

# Usage:
#   ./collect_astrometry_pngs_and_results.sh /home/noamse/KMT/data/Experiments/Comb_blend_all
#   ./collect_astrometry_pngs_and_results.sh EXP_ROOT DEST_DIR
#
# If DEST_DIR not given, defaults to EXP_ROOT/astrometry_pars

EXP_ROOT="${1:-$(pwd)}"
EXP_ROOT="$(realpath "$EXP_ROOT")"
DEST_DIR="${2:-$EXP_ROOT/astrometry_pars}"
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

  # Find all relevant files in event root:
  #   - chi2_3panel*.png
  #   - Dchi2_*.png
  #   - correl_*.png
  #   - results_*.csv
  mapfile -t files < <(find "$evdir" -maxdepth 1 -type f \( \
      -name "chi2_3panel*.png" -o \
      -name "Dchi2_*.png"      -o \
      -name "correl_*.png"     -o \
      -name "results_*.csv" \
    \) | sort)

  if (( ${#files[@]} == 0 )); then
    echo "[$event] no matching PNG/CSV files"
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
echo "Events with no matching files: $events_no_files"
echo "Output in: $DEST_DIR"

