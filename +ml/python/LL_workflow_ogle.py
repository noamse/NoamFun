#!/usr/bin/env python3
"""
High-level workflow script to orchestrate all the main
procedures in the WIS experiment. It is designed so that
one run is processing one event by doing the following:
--> Formatting of the data files (Source*.csv)
--> Running the experiment (loop over all stars in the field)
--> Fetching the results
--> Plotting the results

Input expected from the user:
--> Path to the event directory event_path (containing Source*.csv files)
--> Name run_label to recognize output of the run (default: test)
--> Path to the experiment exp_path (default: {event_path}/{run_label})
--> Path to the auxiliary photometry file (mandatory for this particular experiment)
--> Path to the configuration file(s) location config_path
--> RA/Dec coordinates

Additions in this revision:
- User option to enable/disable OGLE auxiliary photometry:
    --use_ogle (default) / --no_ogle
- (Optional but recommended for stability) User option to enable/disable plotting:
    --plot (default) / --no_plot
  This avoids worker crashes when running in parallel / headless environments.
"""

import pandas as pd
import numpy as np
from typing import Optional
import matplotlib.pyplot as plt
import matplotlib as mpl
from matplotlib.ticker import AutoMinorLocator

import sys
import json
import os
from pathlib import Path
from concurrent.futures import ProcessPoolExecutor, as_completed

from LL_WIS.LL_experiment import ExperimentWIS
from LL_libs import LL_aux_lib as LLaux
from LL_libs.LL_plot_lib import PlotManager


class RunEvent:
    def __init__(self, event_path, config_path, exp_path=None, run_label='test'):
        self.event_path = event_path
        self.config_path = config_path
        self.run_label = run_label

        if exp_path is None:
            print("Default directory for the experiment will be created at")
            print(f"{event_path}/{self.run_label}")
            Path(f'{event_path}/{self.run_label}').mkdir(parents=True, exist_ok=True)
            self.exp_path = f'{event_path}/{self.run_label}'
        else:
            print("Path to the experiment given:")
            print(f"{exp_path}")
            Path(f'{exp_path}').mkdir(parents=True, exist_ok=True)
            self.exp_path = exp_path

    def run_ExperimentWIS_mcmc_event_phot(self, aux_phot_path):
        self.E.run_mcmc_event_phot(aux_phot_path)

    def format_data(self):
        for filepath in Path(self.event_path).glob('Source_*.csv'):
            i = filepath.name.split(".")[0].split("_")[-1]
            src_file = np.genfromtxt(str(filepath), delimiter=',', skip_header=1)

            # Separate into photometry and astrometry
            JD = src_file[:, 0]
            X = src_file[:, 1]
            Y = src_file[:, 2]
            I = src_file[:, 3]
            I_err = src_file[:, 4]
            X_err = src_file[:, 5]
            Y_err = src_file[:, 5]

            target_A = np.array([JD, Y, Y_err, -X, X_err]).T
            target_P = np.array([JD, I, I_err]).T

            target_A_cln = target_A[(X_err > 0) & (Y_err > 0)]
            target_P_cln = target_P[(X_err > 0) & (Y_err > 0)]

            np.savetxt(f"{self.exp_path}/data_A_{i}.txt", target_A_cln, fmt='%.6f')
            np.savetxt(f"{self.exp_path}/data_P_{i}.txt", target_P_cln, fmt='%.6f')

    def init_ExperimentWIS(self, aux_phot_path, ra=None, dec=None):
        E = ExperimentWIS(self.exp_path, self.config_path)

        # config 1
        LLaux.update_yaml(E.config_1, 'optional', 'aux_phot', aux_phot_path)
        LLaux.update_yaml(E.config_1, 'optional', 'out_path', self.exp_path)
        # config 2
        LLaux.update_yaml(
            E.config_2, 'optional', 'aux_phot',
            f'{self.exp_path}/params_photo-aux_{E.init_1.label}_best.json'
        )

        # coordinates
        if ra is not None:
            LLaux.update_yaml(E.config_1, 'positional', 'ra', ra)
            LLaux.update_yaml(E.config_2, 'positional', 'ra', ra)
        if dec is not None:
            LLaux.update_yaml(E.config_1, 'positional', 'dec', dec)
            LLaux.update_yaml(E.config_2, 'positional', 'dec', dec)

        self.E = E

    def run_ExperimentWIS(self):
        self.E.run_aux_phot()
        self.E.run_loop()

    def run_ExperimentWIS_phot(self):
        print(str(self.E.config_1), str(self.E.config_2))
        self.E.run_aux_phot()

    def run_ExperimentWIS_astrometry(self):
        self.E.run_loop()

    def fetch_data(self):
        label = self.E.init_2.label
        records = []

        for src_file in Path(self.event_path).glob('Source_*.csv'):
            i = src_file.name.split('.')[0].split('_')[-1]

            mcmc_path = f'{self.exp_path}/fit_{i}/params_MCMC_{label}.json'
            unlensed_path = f'{self.exp_path}/fit_{i}/params_unlensed_before_gen_{label}.json'

            # load full MCMC dict (ALL params)
            mcmc = read_json_dict(mcmc_path)

            # unlensed chi2 only
            unlensed = read_json_dict(unlensed_path)
            chi2_unlensed = unlensed.get("chi2", np.nan)

            # derived quantities
            pmN = mcmc.get('musN', np.nan)
            pmE = mcmc.get('musE', np.nan)
            N0 = mcmc.get('N0', np.nan)
            E0 = mcmc.get('E0', np.nan)

            pm = np.sqrt(pmE**2 + pmN**2)
            pos = np.sqrt(N0**2 + E0**2)

            mag0 = np.loadtxt(f'{self.exp_path}/fit_{i}/meanmag_{label}.txt')
            thetaE_err = np.loadtxt(f'{self.exp_path}/fit_{i}/thetaE_err_{label}.txt')
            dof = np.loadtxt(f'{self.exp_path}/fit_{i}/dof_{label}.txt')

            results_D = {'starno': i}
            results_D.update(mcmc)
            results_D.update({
                'pos': pos,
                'pm': pm,
                'mag0': mag0,
                'thetaE_err': thetaE_err,
                'dof': dof,
                'chi2_unlensed': chi2_unlensed
            })

            records.append(results_D)

        df = pd.DataFrame(records)
        df.to_csv(f'{self.exp_path}/results_{self.run_label}.csv', index=False)

        print("The master output file for all stars is written at")
        print(f'{self.exp_path}/results_{self.run_label}.csv')


def read_json(path, key):
    with open(path) as f:
        data = json.load(f)
        try:
            return data[key]
        except KeyError:
            print("KeyError while reading json file!")
            return None


def read_json_dict(path):
    with open(path, "r") as f:
        return json.load(f)


def _event_base_kmt(event: str) -> str:
    """event like 'kmt210005_41' -> 'kmt210005'"""
    return event.split("_")[0]


def _find_ogle_lc_file(ogle_root: Path, event: str) -> Optional[Path]:
    """
    Look for an OGLE phot.dat under:
      ogle_root/<kmt_base>/*.dat  or ogle_root/<kmt_base>/**/*.dat
    Returns the first match, preferring 'phot.dat' if present.
    """
    kmt_base = _event_base_kmt(event)
    d = ogle_root / kmt_base
    if not d.is_dir():
        return None

    cand = list(d.rglob("*phot.dat"))
    if cand:
        return cand[0]

    cand = list(d.rglob("*.dat"))
    return cand[0] if cand else None


def main(
    run_label="Noam_phot",
    event="kmt210005_41",
    ra=269.097645,
    dec=-30.407865,
    EventInd=244,
    event_root="/home/noamse/KMT/data/CatsKMT",
    exp_root="/data4/KMT/data/Experiments",
    config_path="/home/noamse/KMT/code/config",
    ogle_root="/home/noamse/KMT/OGLELC",
    use_ogle: bool = True,
    do_plot: bool = True,
):
    """
    Run WIS experiment for a single event.

    use_ogle:
        If True, will try OGLE first (if available), else fallback to KMTNet then fallback file.
        If False, skips OGLE and tries KMTNet then fallback file.

    do_plot:
        If True, run PlotManager plotting.
        If False, skip plotting (recommended for parallel runs / headless nodes).
    """
    event_path = f"{event_root}/{event}"
    exp_path = f"{exp_root}/{run_label}/{event}"

    # 1) OGLE (optional)
    ogle_aux = None
    if use_ogle:
        ogle_root_p = Path(ogle_root).expanduser()
        ogle_aux = _find_ogle_lc_file(ogle_root_p, event)

    # 2) KMTNet provided LC
    kmtnet_aux = Path(f"/home/noamse/KMT/data/CatsKMT/lightcurves/{event}_lightcurve.txt")

    # 3) Old fallback
    fallback_aux = Path(f"{exp_path}/data_P_{EventInd}.txt")

    # Choose which one to use
    if use_ogle and ogle_aux is not None and ogle_aux.is_file():
        aux_phot_path = str(ogle_aux)
        print(f"Using OGLE EWS lightcurve: {aux_phot_path}")
    elif kmtnet_aux.is_file():
        aux_phot_path = str(kmtnet_aux)
        if use_ogle:
            print(f"OGLE LC not found, using KMTNet lightcurve: {aux_phot_path}")
        else:
            print(f"Using KMTNet lightcurve (OGLE disabled): {aux_phot_path}")
    else:
        aux_phot_path = str(fallback_aux)
        if use_ogle:
            print(f"OGLE+KMTNet lightcurves not found, using fallback: {aux_phot_path}")
        else:
            print(f"KMTNet lightcurve not found (OGLE disabled), using fallback: {aux_phot_path}")

    print("\n--- Running WIS experiment ---")
    print(f"Run label:     {run_label}")
    print(f"Event:         {event}")
    print(f"Event index:   {EventInd}")
    print(f"RA, Dec:       ({ra}, {dec})")
    print(f"Event path:    {event_path}")
    print(f"Exp path:      {exp_path}")
    print(f"Config path:   {config_path}")
    print(f"Use OGLE:      {use_ogle}")
    print(f"Do plotting:   {do_plot}")
    print("---------------------------------------\n")

    run = RunEvent(event_path, config_path, exp_path, run_label)
    run.format_data()
    run.init_ExperimentWIS(aux_phot_path, ra=ra, dec=dec)

    run.run_ExperimentWIS()
    run.fetch_data()

    if do_plot:
        pm = PlotManager(run)
        pm.plot_3panel()
        pm.plot_corr()
        pm.plot_Dchi2()
        plt.close("all")


# ---------------- Parallel batch runner ----------------

def _run_one_row(job):
    """
    Worker for execution.
    job can be:
      (row_dict, run_label)
      (row_dict, run_label, use_ogle)
      (row_dict, run_label, use_ogle, do_plot)
    """
    if len(job) == 2:
        row_dict, run_label = job
        use_ogle = True
        do_plot = False
    elif len(job) == 3:
        row_dict, run_label, use_ogle = job
        do_plot = False
    else:
        row_dict, run_label, use_ogle, do_plot = job

    print("\n===============================")
    print(f" Processing NumID: {row_dict['NumID']}  (FieldID: {row_dict['FieldID']})")
    print("===============================\n")

    ra = float(row_dict["RA"])
    dec = float(row_dict["Dec"])
    EventInd = int(row_dict["EventInd"])

    CatsPath = str(row_dict["CatsPath"]).rstrip("/")
    event = CatsPath.split("/")[-1]
    basedir = os.path.dirname(CatsPath) + "/"

    main(
        run_label=run_label,
        event=event,
        ra=ra,
        dec=dec,
        EventInd=EventInd,
        event_root=basedir,
        use_ogle=use_ogle,
        do_plot=do_plot,
    )

    return row_dict["NumID"]


def run_all_from_csv_serial(csv_path, run_label="TestRun", n_workers=None, use_ogle=True, do_plot=True):
    df = pd.read_csv(csv_path)
    df_ok = df[df["Accepted"] == 1].copy()

    print(f"Found {len(df_ok)} accepted fields with Accepted == 1.")

    for k, (_, row) in enumerate(df_ok.iterrows(), start=1):
        row_dict = row.to_dict()
        numid = row_dict.get("NumID", "UNKNOWN")

        print(f"\n[{k}/{len(df_ok)}] Running NumID {numid} ...")
        try:
            finished_numid = _run_one_row((row_dict, run_label, use_ogle, do_plot))
            print(f"✅ Finished NumID {finished_numid}")
        except Exception as e:
            print(f"❌ Error for NumID {numid}: {e}")


def run_all_from_csv(csv_path, run_label="TestRun", n_workers=None, use_ogle=True, do_plot=False):
    df = pd.read_csv(csv_path)
    df_ok = df[df["Accepted"] == 1].copy()

    print(f"Found {len(df_ok)} accepted fields with Accepted == 1.")

    jobs = [(row.to_dict(), run_label, use_ogle, do_plot) for _, row in df_ok.iterrows()]

    with ProcessPoolExecutor(max_workers=n_workers) as ex:
        futures = [ex.submit(_run_one_row, job) for job in jobs]
        for fut in as_completed(futures):
            try:
                numid = fut.result()
                print(f"✅ Finished NumID {numid}")
            except Exception as e:
                print(f"❌ Error in worker: {e}")


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(
        description="Run WIS pipeline over CSV-selected events (parallel or serial)."
    )

    parser.add_argument(
        "--csv",
        type=str,
        required=True,
        help="Path to the AstrometryField_Inspect CSV file"
    )

    parser.add_argument(
        "--run_label",
        type=str,
        default="TestRun",
        help="Label for the experiment run (default: TestRun)"
    )

    parser.add_argument(
        "--n_workers",
        type=int,
        default=None,
        help="Number of parallel workers (default: use all cores)"
    )

    # OGLE option
    parser.add_argument(
        "--use_ogle",
        dest="use_ogle",
        action="store_true",
        help="Use OGLE lightcurve if available (default)."
    )
    parser.add_argument(
        "--no_ogle",
        dest="use_ogle",
        action="store_false",
        help="Disable OGLE usage; use KMTNet lightcurve or fallback only."
    )
    parser.set_defaults(use_ogle=True)

    # Plot option
    parser.add_argument(
        "--plot",
        dest="do_plot",
        action="store_true",
        help="Enable plotting (default)."
    )
    parser.add_argument(
        "--no_plot",
        dest="do_plot",
        action="store_false",
        help="Disable plotting (recommended for parallel/headless runs)."
    )
    parser.set_defaults(do_plot=True)

    # Mode selection
    parser.add_argument(
        "--parallel",
        action="store_true",
        help="Run in parallel using ProcessPoolExecutor (default: serial)."
    )

    args = parser.parse_args()

    if args.parallel:
        # For parallel runs, default do_plot to False unless explicitly requested
        run_all_from_csv(
            args.csv,
            run_label=args.run_label,
            n_workers=args.n_workers,
            use_ogle=args.use_ogle,
            do_plot=args.do_plot
        )
    else:
        run_all_from_csv_serial(
            args.csv,
            run_label=args.run_label,
            n_workers=args.n_workers,
            use_ogle=args.use_ogle,
            do_plot=args.do_plot
        )

