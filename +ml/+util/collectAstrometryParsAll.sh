#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./collect_astrometry_pars.sh /home/noamse/KMT/data/Experiments/Comb_A_v1
# If no arg is given, uses current directory.
EXP_ROOT="${1:-$(pwd)}"
EXP_ROOT="$(realpath "$EXP_ROOT")"

if [[ ! -d "$EXP_ROOT" ]]; then
  echo "ERROR: EXP_ROOT not a directory: $EXP_ROOT" >&2
  exit 1
fi

OUT_CSV="${EXP_ROOT}/collect_astrometry_pars.csv"

echo "Experiment root: $EXP_ROOT"
echo "Output CSV:      $OUT_CSV"
echo

# Header for output CSV (adjust if your columns differ)
echo "Event,EventInd,starno,chi2,chi2_unlensed,thetaE,phi,pos,musN,musE,pm,mag0,thetaE_err,dof,results_csv,chi2_3panel_png,dchi2_png,correl_png" > "$OUT_CSV"

shopt -s nullglob

for evdir in "$EXP_ROOT"/kmt??????_??; do
  [[ -d "$evdir" ]] || continue
  event="$(basename "$evdir")"

  # --- find results_*.csv (newest if multiple) ---
  results_candidates=( "$evdir"/results_*.csv )
  results_csv=""
  if (( ${#results_candidates[@]} > 0 )); then
    results_csv="$(ls -t "${results_candidates[@]}" | head -n 1)"
  fi

  # --- find newest chi2_3panel_*.png ---
  chi2_candidates=( "$evdir"/chi2_3panel_*.png )
  chi2_3panel_png=""
  if (( ${#chi2_candidates[@]} > 0 )); then
    chi2_3panel_png="$(ls -t "${chi2_candidates[@]}" | head -n 1)"
  fi

  # --- find newest Dchi2_hist_*.png ---
  dchi2_candidates=( "$evdir"/Dchi2_hist_*.png )
  dchi2_png=""
  if (( ${#dchi2_candidates[@]} > 0 )); then
    dchi2_png="$(ls -t "${dchi2_candidates[@]}" | head -n 1)"
  fi

  # --- find newest correl_*.png ---
  correl_candidates=( "$evdir"/correl_*.png )
  correl_png=""
  if (( ${#correl_candidates[@]} > 0 )); then
    correl_png="$(ls -t "${correl_candidates[@]}" | head -n 1)"
  fi

  if [[ -z "$results_csv" ]]; then
    echo "⚠️  [$event] No results_*.csv found, skipping."
    continue
  fi

  echo "[$event]"
  echo "  results:  $(basename "$results_csv")"
  [[ -n "$chi2_3panel_png" ]] && echo "  chi2_3panel: $(basename "$chi2_3panel_png")"
  [[ -n "$dchi2_png"       ]] && echo "  Dchi2_hist:  $(basename "$dchi2_png")"
  [[ -n "$correl_png"      ]] && echo "  correl:      $(basename "$correl_png")"

  # --- append rows from results CSV ---
  awk -F',' -v OFS=',' \
      -v event="$event" \
      -v results_csv="$results_csv" \
      -v chi2_3panel_png="$chi2_3panel_png" \
      -v dchi2_png="$dchi2_png" \
      -v correl_png="$correl_png" \
      '
      NR==1 {
        # map column names -> indices
        for (i=1; i<=NF; i++) {
          gsub(/^[ \t]+|[ \t]+$/, "", $i)
          idx[$i]=i
        }
        next
      }
      {
        starno = $(idx["starno"])
        chi2   = $(idx["chi2"])
        chi2_unlensed = (("chi2_unlensed" in idx) ? $(idx["chi2_unlensed"]) : "")
        thetaE = $(idx["thetaE"])
        phi    = $(idx["phi"])
        pos    = $(idx["pos"])
        musN   = $(idx["musN"])
        musE   = $(idx["musE"])
        mag0   = $(idx["mag0"])
        thetaE_err = $(idx["thetaE_err"])
        dof    = $(idx["dof"])

        EventInd = starno
        pm = sqrt(musN*musN + musE*musE)

        print event, EventInd, starno, chi2, chi2_unlensed, thetaE, phi, pos, musN, musE, pm, mag0, thetaE_err, dof, results_csv, chi2_3panel_png, dchi2_png, correl_png
      }
      ' "$results_csv" >> "$OUT_CSV"

done

echo
echo "Done. Wrote: $OUT_CSV"

