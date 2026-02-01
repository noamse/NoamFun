#!/usr/bin/env python3
import argparse
import shutil
import sys
import json
import pandas as pd
import numpy as np
from pathlib import Path

def get_astrometry_data(event_dir):
    """
    Scans fit_*** directories in an event folder.
    Returns a pandas DataFrame containing:
      - Parameters from params_MCMC_WIS-2.json (Lensed)
      - chi2_unlensed from params_unlensed_before_gen_WIS-2.json
      - thetaE error from thetaE_err_WIS-2.txt
      - Median magnitude from data_P_{id}.txt
    """
    rows = []
    
    # Iterate over all fit_*** directories
    fit_dirs = sorted(list(event_dir.glob("fit_*")))
    
    for fd in fit_dirs:
        if not fd.is_dir():
            continue
            
        # Extract source ID from folder name (e.g. 'fit_101' -> '101')
        try:
            src_id = fd.name.split('_')[-1]
        except:
            src_id = fd.name

        # --- Define File Paths ---
        json_mcmc_path     = fd / "params_MCMC_WIS-2.json"                # Lensed Fit
        json_unlensed_path = fd / "params_unlensed_before_gen_WIS-2.json" # Unlensed Fit (User specified)
        err_path           = fd / "thetaE_err_WIS-2.txt"
        data_p_path        = event_dir / f"data_P_{src_id}.txt"

        if not json_mcmc_path.exists():
            continue

        # 1. Read MCMC Parameters (Lensed)
        try:
            with open(json_mcmc_path, 'r') as f:
                params = json.load(f)
        except Exception as e:
            print(f"  ⚠️ Error reading MCMC JSON in {fd.name}: {e}")
            continue

        # 2. Read Unlensed Chi2 (from params_unlensed_before_gen_WIS-2.json)
        chi2_unlensed = None
        if json_unlensed_path.exists():
            try:
                with open(json_unlensed_path, 'r') as f:
                    unlensed_params = json.load(f)
                    chi2_unlensed = unlensed_params.get('chi2')
            except:
                pass

        # 3. Read ThetaE Error
        thetaE_err = None
        if err_path.exists():
            try:
                val_str = err_path.read_text().strip().split()[0]
                thetaE_err = float(val_str)
            except:
                pass

        # 4. Calculate Median Magnitude
        mag_median = None
        if data_p_path.exists():
            try:
                # Load 2nd column (magnitude)
                mags = np.genfromtxt(data_p_path, usecols=1)
                if np.ndim(mags) == 0:
                    mag_median = float(mags)
                else:
                    mag_median = float(np.nanmedian(mags))
            except:
                pass

        # 5. Construct Row
        row = {'source_id': src_id}
        row.update(params)  # Adds 'chi2' (lensed) and other params
        row['chi2_unlensed'] = chi2_unlensed
        row['thetaE_err'] = thetaE_err
        row['mag_median'] = mag_median
        
        rows.append(row)

    if not rows:
        return None

    df = pd.DataFrame(rows)
    
    # Organize columns (Key metrics first)
    priority_cols = ['source_id', 'mag_median', 'chi2', 'chi2_unlensed', 'thetaE', 'thetaE_err']
    cols = priority_cols + [c for c in df.columns if c not in priority_cols]
    
    # Filter to ensure we only list columns that actually exist
    final_cols = [c for c in cols if c in df.columns]
    
    return df[final_cols]

def collect_files(exp_root, dest_dir, mode):
    exp_path = Path(exp_root).resolve()
    dest_path = Path(dest_dir).resolve()

    if not exp_path.is_dir():
        print(f"Error: Experiment root is not a directory: {exp_path}")
        sys.exit(1)

    print(f"--- Collecting results (Mode: {mode}) ---")
    print(f"Source:      {exp_path}")
    print(f"Destination: {dest_path}")
    
    dest_path.mkdir(parents=True, exist_ok=True)

    copied_count = 0
    events_processed = 0
    
    event_dirs = sorted([d for d in exp_path.glob("kmt??????_??") if d.is_dir()])

    for ev_dir in event_dirs:
        event_name = ev_dir.name
        out_event_dir = dest_path / event_name
        
        files_to_copy = []
        df_astro = None

        if mode in ["astro", "all"]:
            # Copy Plot Images
            files_to_copy.extend(list(ev_dir.glob("chi2_3panel*.png")))
            files_to_copy.extend(list(ev_dir.glob("Dchi2_*.png")))
            files_to_copy.extend(list(ev_dir.glob("correl_*.png")))
            
            # Aggregate CSV Data (Replacing the need to copy the raw results_*.csv)
            df_astro = get_astrometry_data(ev_dir)

        if mode in ["photo", "all"]:
            files_to_copy.extend(list(ev_dir.glob("params_photo-aux_*.json")))
            files_to_copy.extend(list(ev_dir.glob("lc_aux-phot_*.png")))
            files_to_copy.extend(list(ev_dir.glob("aux_fit_diagnostic.png")))

        if not files_to_copy and df_astro is None:
            continue

        out_event_dir.mkdir(parents=True, exist_ok=True)

        # A. Save Aggregated Astrometry CSV
        if df_astro is not None:
            csv_name = "collected_astrometry_params.csv"
            out_csv = out_event_dir / csv_name
            try:
                df_astro.to_csv(out_csv, index=False)
            except Exception as e:
                print(f"  ⚠️ Failed to write CSV for {event_name}: {e}")

        # B. Copy Files
        for src in files_to_copy:
            dst = out_event_dir / src.name
            try:
                shutil.copy2(src, dst)
                copied_count += 1
            except Exception as e:
                print(f"  ⚠️ Failed to copy {src.name}: {e}")
        
        events_processed += 1

    print(f"Done. Processed {events_processed} events.")
    print(f"Copied {copied_count} static files.")
    print("-" * 40)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("exp_root", nargs="?", default=".", help="Experiment root directory")
    parser.add_argument("--mode", choices=["astro", "photo", "all"], default="all")
    parser.add_argument("--dest", default=None, help="Custom destination directory")

    args = parser.parse_args()
    
    root = Path(args.exp_root).resolve()
    dest_dir = Path(args.dest) if args.dest else root / "collected_results"

    collect_files(root, dest_dir, args.mode)

if __name__ == "__main__":
    main()