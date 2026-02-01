import argparse
import json
import yaml
import shutil
import time
import pickle
import copy
from pathlib import Path
import numpy as np
import matplotlib.pyplot as plt
from typing import Optional

# Custom Libraries
from LL_libs import LL_init_lib as LLinit
from LL_libs import LL_models_lib as LLmod
from LL_libs import LL_aux_lib as LLaux

# --- HELPER FUNCTIONS ---

def bin_by_days_robust(t, y, bin_days=10.0):
    t = np.asarray(t); y = np.asarray(y)
    good = np.isfinite(t) & np.isfinite(y)
    t, y = t[good], y[good]
    if t.size == 0: return np.array([]), np.array([]), np.array([]), np.array([])
    tmin, tmax = np.min(t), np.max(t)
    edges = np.arange(tmin, tmax + bin_days, bin_days)
    bin_idx = np.digitize(t, edges) - 1
    centers, medians, stds, neps = [], [], [], []
    for k in range(len(edges) - 1):
        m = bin_idx == k
        if not np.any(m): continue
        yk = y[m]
        med_val = np.nanmedian(yk)
        mad = np.nanmedian(np.abs(yk - med_val))
        sigma = 1.4826 * mad
        err = sigma / np.sqrt(len(yk))
        centers.append(0.5 * (edges[k] + edges[k + 1]))
        medians.append(med_val)
        stds.append(err)
        neps.append(len(yk))
    return np.array(centers), np.array(medians), np.array(stds), np.array(neps)

def save_mpl_fig(fig, out_dir, tag):
    out_dir = Path(out_dir); out_dir.mkdir(parents=True, exist_ok=True)
    with open(out_dir / f"{tag}.fig.pkl", "wb") as f: pickle.dump(fig, f)

def _event_base_kmt(event: str) -> str:
    return event.split("_")[0]

def _find_ogle_lc_file(ogle_root: Path, event: str) -> Optional[Path]:
    kmt_base = _event_base_kmt(event)
    d = ogle_root / kmt_base
    if not d.is_dir(): return None
    cand = list(d.rglob("*phot.dat"))
    if cand: return cand[0]
    cand = list(d.rglob("*.dat"))
    return cand[0] if cand else None

def select_photometry_file(event, EventInd, exp_path, ogle_root, use_ogle=True):
    ogle_aux = None
    if use_ogle and ogle_root:
        ogle_root_p = Path(ogle_root).expanduser()
        ogle_aux = _find_ogle_lc_file(ogle_root_p, event)
    kmtnet_aux = Path(f"/home/noamse/KMT/data/CatsKMT/lightcurves/{event}_lightcurve.txt")
    fallback_aux = Path(f"{exp_path}/data_P_{EventInd}.txt")
    if use_ogle and ogle_aux is not None and ogle_aux.is_file():
        print(f"Photometry Source (Plotting): OGLE ({ogle_aux})")
        return str(ogle_aux)
    elif kmtnet_aux.is_file():
        print(f"Photometry Source (Plotting): KMTNet ({kmtnet_aux})")
        return str(kmtnet_aux)
    else:
        print(f"Photometry Source (Plotting): Fallback ({fallback_aux})")
        return str(fallback_aux)

def get_fit_tref(exp_path, EventInd):
    fallback_aux = Path(f"{exp_path}/data_P_{EventInd}.txt")
    if fallback_aux.exists():
        try:
            data = np.genfromtxt(fallback_aux, usecols=[0])
            if data.ndim == 0: return data.item()
            tref = np.mean(data)
            print(f"Fit tref derived from {fallback_aux.name}: {tref:.4f}")
            return tref
        except Exception as e:
            print(f"Warning: Could not read {fallback_aux.name} for tref: {e}")
    else:
        print(f"Warning: {fallback_aux.name} missing. tref might be inaccurate.")
    return None

def build_paths(event_num, field, EventInd, exp_root):
    event = f"kmt{int(event_num):06d}_{int(field):02d}"
    base = Path(exp_root) / event
    astro_file = base / f"data_A_{EventInd}.txt"
    config_file_ast = base / "config_WIS-2.yaml"
    config_file_phot = base / "config_WIS-1.yaml"
    jsonFile_ast = base / f"fit_{EventInd}" / "params_MCMC_WIS-2.json"
    jsonFile_phot = base / "params_photo-aux_WIS-1_best.json"
    return event, base, astro_file, config_file_ast, config_file_phot, jsonFile_ast, jsonFile_phot

def load_yaml_config(config_path):
    if not config_path.exists():
        raise FileNotFoundError(f"Config not found: {config_path}")
    with open(config_path, 'r') as f:
        cfg = yaml.safe_load(f)
    pos = cfg.get('positional', {})
    ra = pos.get('ra')
    dec = pos.get('dec')
    if ra is None or dec is None: raise ValueError(f"RA/Dec missing in {config_path}")
    return float(ra), float(dec)

def merge_params_for_model(md, params_phot, params_ast):
    combined_params = []
    for key in md.model_keys:
        val = 0.0
        if key in params_phot: val = params_phot[key]
        elif key in params_ast: val = params_ast[key]
        else:
            if key == 'piE' and 'piE' in params_phot: val = params_phot['piE']
            elif key == 'phi' and 'phi' in params_phot: val = params_phot['phi']
            elif key == 'piEN' and 'piEN' in params_phot: val = params_phot['piEN']
            elif key == 'piEE' and 'piEE' in params_phot: val = params_phot['piEE']
        combined_params.append(val)
    return combined_params

def get_astrometric_components(md, t):
    if md.qn is not None and len(md.qn) == len(t):
        qn, qe = md.qn, md.qe
    else:
        t0par = md.paramsD.get('t0_par', md.paramsD['t0'])
        qn, qe = LLaux.get_qarr(t, md.ra, md.dec, t0par)
    tau, beta = md.rel_trajectory(t, qn, qe)
    dN, dE = md.ulens_shift(tau, beta)
    N_full, E_full = md.total_shift(t, tau, beta, qn, qe)
    N_base = N_full - dN
    E_base = E_full - dE
    return N_full, E_full, N_base, E_base

def create_param_text(md_ast, md_phot=None):
    """
    Generates a formatted string of key parameters, including
    derived Mass and Distance (assuming DS=8kpc).
    """
    p_ast = md_ast.paramsD
    p_phot = md_phot.paramsD if md_phot is not None else p_ast

    # 1. Photometry Parameters (Prioritize md_phot)
    t0 = p_phot.get('t0', p_ast.get('t0', 0))
    u0 = p_phot.get('u0', p_ast.get('u0', 0))
    piEN = p_phot.get('piEN', p_ast.get('piEN', 0))
    piEE = p_phot.get('piEE', p_ast.get('piEE', 0))
    fs = p_phot.get('fs', p_ast.get('fs', 0))
    
    # 2. Shared/Astrometry Parameters
    tE = p_ast.get('tE', p_phot.get('tE', 0))
    mag0 = p_ast.get('mag0', p_phot.get('mag0', 0))
    
    # 3. Pure Astrometry Parameters (Prioritize md_ast)
    thetaE = p_ast.get('thetaE', 0)
    
    # Handle phi
    phi = p_ast.get('phi')
    if phi is None and md_phot is not None:
        phi = p_phot.get('phi', 0)
    elif phi is None:
        phi = 0.0

    # --- Derived Physical Parameters ---
    # Constants
    kappa = 8.144  # mas / M_sun
    DS_kpc = 8.0   # Assumed Source Distance
    
    # Magnitudes
    piE_mag = np.sqrt(piEN**2 + piEE**2)
    
    # 1. Lens Mass: M = thetaE / (kappa * piE)
    if piE_mag > 1e-6:
        M_L = thetaE / (kappa * piE_mag)
    else:
        M_L = 0.0
        
    # 2. Lens Distance: DL = (1/DS + piE*thetaE / AU)^-1
    # Note: pi_rel (mas) = piE * thetaE (mas)
    # DL (kpc) = 1 / (pi_rel(mas) + 1/DS(kpc))
    pi_rel_mas = piE_mag * thetaE
    pi_S_mas = 1.0 / DS_kpc
    pi_L_mas = pi_rel_mas + pi_S_mas
    
    if pi_L_mas > 1e-6:
        D_L = 1.0 / pi_L_mas
    else:
        D_L = 0.0

    txt = (
        f"$t_0$: {t0:.2f}\n"
        f"$u_0$: {u0:.3f}\n"
        f"$t_E$: {tE:.2f} d\n"
        f"$\\theta_E$: {thetaE:.2f} mas\n"
        f"$\\phi$: {phi:.2f} rad\n"
        f"$\\pi_{{EN}}$: {piEN:.3f}\n"
        f"$\\pi_{{EE}}$: {piEE:.3f}\n"
        f"$mag_0$: {mag0:.2f}\n"
        f"$f_s$: {fs:.2f}\n"
        f"---\n"
        f"$M_L$: {M_L:.2f} $M_\\odot$\n"
        f"$D_L$: {D_L:.2f} kpc"
    )
    return txt

# --- MAIN ---

def main(event_num, field, EventInd, exp_root, out_dir=None, ogle_root=None, use_ogle=True, bin_days = 10.0):
    
    event_name, base_dir, astro_file, cfg_ast_path, cfg_phot_path, jsonFile_ast, jsonFile_phot = build_paths(
        event_num, field, EventInd, exp_root
    )

    if out_dir:
        out_path = Path(out_dir)
        print(f"Using Custom Output Dir: {out_path}")
    else:
        exp_name = Path(exp_root).name
        out_path = Path(f"/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/{exp_name}/plots_summary/{event_name}")
        print(f"Using Default Output Dir: {out_path}")

    if not out_path.exists():
        out_path.mkdir(parents=True, exist_ok=True)

    print(f"\n--- Processing {event_name} Src: {EventInd} ---")

    photo_file = select_photometry_file(event_name, EventInd, base_dir, ogle_root, use_ogle)
    tref_fit = get_fit_tref(base_dir, EventInd)

    try:
        ra, dec = load_yaml_config(cfg_ast_path)
    except Exception as e:
        print(f"Error reading config: {e}")
        return

    stamp = time.strftime("%Y%m%d_%H%M%S")
    
    temp_cfg_ast = out_path / f"temp_cfg_ast_{stamp}.yaml"
    shutil.copy(cfg_ast_path, temp_cfg_ast)
    LLaux.update_yaml(str(temp_cfg_ast), "optional", "astro_file", str(astro_file))
    setup_ast = LLinit.LLSetup(str(temp_cfg_ast))
    data_arr_A = setup_ast.data_arr_A
    temp_cfg_ast.unlink(missing_ok=True)

    temp_cfg_phot = out_path / f"temp_cfg_phot_{stamp}.yaml"
    src_cfg = cfg_phot_path if cfg_phot_path.exists() else cfg_ast_path
    shutil.copy(src_cfg, temp_cfg_phot)
    LLaux.update_yaml(str(temp_cfg_phot), "optional", "photo_file", str(photo_file))
    setup_phot = LLinit.LLSetup(str(temp_cfg_phot))
    data_arr_P = setup_phot.data_arr_P
    temp_cfg_phot.unlink(missing_ok=True)

    if data_arr_P is None or data_arr_A is None:
        print("Error: Missing data arrays.")
        return
    
    if tref_fit is None:
        print("Warning: Using mean of loaded photometry for tref.")
        tref_fit = np.mean(data_arr_P[:,0])

    if not jsonFile_ast.exists() or not jsonFile_phot.exists():
        print(f"Error: Missing JSON params.")
        return

    # --- COPY JSON PARAM FILES TO OUTPUT DIR ---
    print(f"Copying JSON parameter files to: {out_path}")
    shutil.copy(jsonFile_ast, out_path / jsonFile_ast.name)
    shutil.copy(jsonFile_phot, out_path / jsonFile_phot.name)

    with open(jsonFile_ast, 'r') as f: params_ast = json.load(f)
    with open(jsonFile_phot, 'r') as f: params_phot = json.load(f)

    # --- INITIALIZE MODELS ---
    plx_par_ast = setup_ast.plx_par
    print(f"Astrometry plx_par: {plx_par_ast}")

    md_ast = LLmod.initiate_model(setup_ast.Amodel, ra, dec, plx_par=plx_par_ast, 
                                  tref=tref_fit, lum_blends=setup_ast.lum_blends)
    params_ast_list = merge_params_for_model(md_ast, params_phot, params_ast)
    md_ast.initiate_params(params_ast_list)

    if 'piEN' in params_phot and 'piEE' in params_phot: plx_par_phot = 'piE'
    elif 'phi' in params_phot: plx_par_phot = 'phi'
    else: plx_par_phot = setup_ast.plx_par
    md_phot = LLmod.initiate_model(setup_ast.Amodel, ra, dec, plx_par=plx_par_phot, 
                                   tref=tref_fit, lum_blends=setup_ast.lum_blends)
    params_phot_list = merge_params_for_model(md_phot, params_phot, params_ast)
    md_phot.initiate_params(params_phot_list)

    # --- GENERATE CURVES ---
    t_cont = LLaux.prep_t_cont(data_arr_P, data_arr_A)
    mod_N_full, mod_E_full, mod_N_base, mod_E_base = get_astrometric_components(md_ast, t_cont)
    sig_N_smooth = mod_N_full - mod_N_base
    sig_E_smooth = mod_E_full - mod_E_base

    tA = data_arr_A[:,0]
    _, _, data_N_base, data_E_base = get_astrometric_components(md_ast, tA)

    _, data_arr_P_cont, _, _ = LLaux.gen_from_input(md_phot, t_cont, t_cont, out_path=str(out_path))
    tm_P = data_arr_P_cont[:,0]; mod_mag = data_arr_P_cont[:,1]

    NA, sigN, EA, sigE = data_arr_A[:,1], data_arr_A[:,2], data_arr_A[:,3], data_arr_A[:,4]
    tP, magP, sigP = data_arr_P[:,0], data_arr_P[:,1], data_arr_P[:,2]
    tm_A = t_cont

    # --- PLOTTING SETUP ---
    
    tb_N, Nb_med, Nb_err, _ = bin_by_days_robust(tA, NA, bin_days=bin_days)
    tb_E, Eb_med, Eb_err, _ = bin_by_days_robust(tA, EA, bin_days=bin_days)

    # Param text block
    param_txt = create_param_text(md_ast, md_phot)

    # =========================================================================
    #  PLOT 1: STANDARD 3-PANEL SUMMARY
    # =========================================================================
    fig, ax = plt.subplots(3, 1, sharex=True, figsize=(8, 9), gridspec_kw={"hspace": 0.05})

    ax[0].plot(tA, NA, '.', color='C0', alpha=0.15, markeredgewidth=0, label='raw')
    if tb_N.size: ax[0].errorbar(tb_N, Nb_med, yerr=Nb_err, fmt='o', ms=5, color='k', mfc='C0', ecolor='k', elinewidth=1.5, capsize=2)
    ax[0].plot(tm_A, mod_N_full, '-', color='C0', alpha=0.8, linewidth=2, label='Full Model')
    ax[0].plot(tm_A, mod_N_base, '--', color='gray', alpha=0.6, linewidth=1.2, label='Background')
    ax[0].set_ylabel('N [mas]'); ax[0].legend(fontsize=9); ax[0].grid(True, alpha=0.3)

    ax[1].plot(tA, EA, '.', color='C1', alpha=0.15, markeredgewidth=0, label='raw')
    if tb_E.size: ax[1].errorbar(tb_E, Eb_med, yerr=Eb_err, fmt='o', ms=5, color='k', mfc='C1', ecolor='k', elinewidth=1.5, capsize=2)
    ax[1].plot(tm_A, mod_E_full, '-', color='C1', alpha=0.8, linewidth=2, label='Full Model')
    ax[1].plot(tm_A, mod_E_base, '--', color='gray', alpha=0.6, linewidth=1.2, label='Background')
    ax[1].set_ylabel('E [mas]'); ax[1].legend(fontsize=9); ax[1].grid(True, alpha=0.3)

    ax[2].errorbar(tP, magP, yerr=sigP, fmt='.', color='k', ms=3, capsize=0, alpha=0.3, label='phot raw')
    ax[2].plot(tm_P, mod_mag, '-', color='r', alpha=0.8, linewidth=1.5, label='Model')
    ax[2].invert_yaxis(); ax[2].set_ylabel('mag'); ax[2].set_xlabel('JD'); ax[2].legend(fontsize=9); ax[2].grid(True, alpha=0.3)

    if len(NA) > 0:
        med_N = np.nanmedian(NA); ax[0].set_ylim(med_N - 50.0, med_N + 50.0)
    if len(EA) > 0:
        med_E = np.nanmedian(EA); ax[1].set_ylim(med_E - 50.0, med_E + 50.0)

    fig.suptitle(f"{event_name}  EventInd={EventInd}", fontsize=12, y=0.98)
    fig.tight_layout(rect=[0, 0, 1, 0.97])
    tag = f"{event_name}_E{EventInd}_3panel_WIS-2"
    fig.savefig(out_path / f"{tag}.png", dpi=200)
    save_mpl_fig(fig, out_path, tag)
    plt.close(fig)

    # =========================================================================
    #  PLOT 2: ASTROMETRIC SIGNAL (Microlensing Deviation Only)
    # =========================================================================
    diff_N = NA - data_N_base
    diff_E = EA - data_E_base
    tb_N_res, Nb_res_med, Nb_res_err, _ = bin_by_days_robust(tA, diff_N, bin_days=10.0)
    tb_E_res, Eb_res_med, Eb_res_err, _ = bin_by_days_robust(tA, diff_E, bin_days=10.0)
    
    _, data_arr_P_pts, _, _ = LLaux.gen_from_input(md_phot, tP, tP)
    res_P = magP - data_arr_P_pts[:, 1]

    fig_res, ax_res = plt.subplots(3, 1, sharex=True, figsize=(8, 9), gridspec_kw={"hspace": 0.05})

    # Add Parameter Text Box to first panel (TOP LEFT)
    ax_res[0].text(0.02, 0.95, param_txt, transform=ax_res[0].transAxes, fontsize=8,
                   verticalalignment='top', horizontalalignment='left',
                   bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

    ax_res[0].axhline(0, color='gray', linestyle='--', linewidth=1)
    ax_res[0].plot(tA, diff_N, '.', color='C0', alpha=0.15, markeredgewidth=0)
    if tb_N_res.size: ax_res[0].errorbar(tb_N_res, Nb_res_med, yerr=Nb_res_err, fmt='o', ms=5, color='k', mfc='C0', ecolor='k', elinewidth=1.5, capsize=2)
    ax_res[0].plot(tm_A, sig_N_smooth, 'k-', lw=2.0, alpha=0.8, label='Signal')
    ax_res[0].set_ylabel(r'$\Delta N_{ML}$ [mas]'); ax_res[0].grid(True, alpha=0.3)

    ax_res[1].axhline(0, color='gray', linestyle='--', linewidth=1)
    ax_res[1].plot(tA, diff_E, '.', color='C1', alpha=0.15, markeredgewidth=0)
    if tb_E_res.size: ax_res[1].errorbar(tb_E_res, Eb_res_med, yerr=Eb_res_err, fmt='o', ms=5, color='k', mfc='C1', ecolor='k', elinewidth=1.5, capsize=2)
    ax_res[1].plot(tm_A, sig_E_smooth, 'k-', lw=2.0, alpha=0.8, label='Signal')
    ax_res[1].set_ylabel(r'$\Delta E_{ML}$ [mas]'); ax_res[1].grid(True, alpha=0.3)

    ax_res[2].errorbar(tP, res_P, yerr=sigP, fmt='.', color='k', ms=3, alpha=0.15)
    ax_res[2].axhline(0, color='r', linestyle='--', alpha=0.5)
    ax_res[2].set_ylabel(r'Res Mag'); ax_res[2].set_xlabel('JD'); ax_res[2].grid(True, alpha=0.3)
    
    ax_res[0].set_ylim(-25, 25); ax_res[1].set_ylim(-25, 25)

    fig_res.suptitle(f"{event_name} Astrometric Deviation (Signal)", fontsize=12, y=0.98)
    fig_res.tight_layout(rect=[0, 0, 1, 0.97])
    tag_res = f"{event_name}_E{EventInd}_AstroSignal"
    fig_res.savefig(out_path / f"{tag_res}.png", dpi=200)
    plt.close(fig_res)

    # =========================================================================
    #  PLOT 3: ZOOM
    # =========================================================================
    try:
        t0, tE = md_ast.paramsD.get('t0'), md_ast.paramsD.get('tE')
        if t0 is not None and tE is not None and tE > 0:
            fig_zres, ax_zres = plt.subplots(3, 1, sharex=True, figsize=(8, 9), gridspec_kw={"hspace": 0.05})
            
            # Add Parameter Text Box to Zoom plot (TOP LEFT)
            ax_zres[0].text(0.02, 0.95, param_txt, transform=ax_zres[0].transAxes, fontsize=8,
                            verticalalignment='top', horizontalalignment='left',
                            bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))

            ax_zres[0].axhline(0, color='gray', linestyle='--', linewidth=1)
            ax_zres[0].plot(tA, diff_N, '.', color='C0', alpha=0.2, markeredgewidth=0)
            if tb_N_res.size: ax_zres[0].errorbar(tb_N_res, Nb_res_med, yerr=Nb_res_err, fmt='o', ms=5, color='k', mfc='C0', ecolor='k', elinewidth=1.5, capsize=2)
            ax_zres[0].plot(tm_A, sig_N_smooth, 'k-', lw=2.5, alpha=0.8)
            ax_zres[0].set_ylabel(r'$\Delta N_{ML}$ [mas]'); ax_zres[0].grid(True, alpha=0.3)

            ax_zres[1].axhline(0, color='gray', linestyle='--', linewidth=1)
            ax_zres[1].plot(tA, diff_E, '.', color='C1', alpha=0.2, markeredgewidth=0)
            if tb_E_res.size: ax_zres[1].errorbar(tb_E_res, Eb_res_med, yerr=Eb_res_err, fmt='o', ms=5, color='k', mfc='C1', ecolor='k', elinewidth=1.5, capsize=2)
            ax_zres[1].plot(tm_A, sig_E_smooth, 'k-', lw=2.5, alpha=0.8)
            ax_zres[1].set_ylabel(r'$\Delta E_{ML}$ [mas]'); ax_zres[1].grid(True, alpha=0.3)

            ax_zres[2].errorbar(tP, res_P, yerr=sigP, fmt='.', color='k', ms=3, alpha=0.3)
            ax_zres[2].axhline(0, color='r', linestyle='--', alpha=0.5)
            ax_zres[2].set_ylabel(r'Res Mag'); ax_zres[2].set_xlabel('JD'); ax_zres[2].grid(True, alpha=0.3)

            xlim_min = t0 - 2.0 * tE; xlim_max = t0 + 2.0 * tE
            for a in ax_zres: a.set_xlim(xlim_min, xlim_max)
            ax_zres[0].set_ylim(-15, 15); ax_zres[1].set_ylim(-15, 15)
            
            m_phot = (tP >= xlim_min) & (tP <= xlim_max)
            if np.any(m_phot):
                yw = res_P[m_phot]; mv, sv = np.nanmedian(yw), np.nanstd(yw)
                ax_zres[2].set_ylim(mv - 3.0*sv, mv + 3.0*sv)

            fig_zres.suptitle(f"{event_name} AstroSignal ZOOM (+/- 2tE)", fontsize=12, y=0.98)
            fig_zres.tight_layout(rect=[0, 0, 1, 0.97])
            fig_zres.savefig(out_path / f"{tag_res}_ZOOM.png", dpi=200)
            plt.close(fig_zres)
    except Exception as e:
        print(f"Zoom failed: {e}")

    print("\nDone.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--event_num", type=int, required=True)
    parser.add_argument("--field", type=int, required=True)
    parser.add_argument("--EventInd", type=int, required=True)
    parser.add_argument("--exp_root", type=str, required=True)
    parser.add_argument("--out_dir", type=str, default=None)
    parser.add_argument("--ogle_root", type=str, default="/home/noamse/KMT/OGLELC")
    parser.add_argument("--use_ogle", dest="use_ogle", action="store_true")
    parser.add_argument("--no_ogle", dest="use_ogle", action="store_false")
    parser.add_argument("--bin_days", type=float, default=10.0)
    parser.set_defaults(use_ogle=True)

    args = parser.parse_args()

    main(args.event_num, args.field, args.EventInd, args.exp_root, 
         out_dir=args.out_dir, ogle_root=args.ogle_root, use_ogle=args.use_ogle
         , bin_days=args.bin_days)