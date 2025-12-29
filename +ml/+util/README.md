Here I will describe the procedure for a new Experiment using the pipeline.
First, to run the ml fitter:

python3 /home/noamse/KMT/code/scripts/LL_workflow_WIS_Comb.py --run_label Comb_blend_all --csv /home/noamse/KMT/data/test/AstrometryField_Inspect_A.csv --n_workers 32



The experiment output will appear in 
rootDir=/home/noamse/KMT/data/Experiments/Comb_blend_all/

Now, I wrote some scripts to collect the results into some accessible hirarchy.

## To extract the photometry data
run 
bash /home/noamse/matlab/NoamFun/+ml/+util/Photometry_collect_params_and_pngs.sh /data4/KMT/data/Experiments/exp1_?

This will appear in rootDir/photometry_outputs/kmt%%%%%%_##

## To extract the astrometry data
run
bash /home/noamse/matlab/NoamFun/+ml/+util/Astrometry_collect_params_pngs.sh /data4/KMT/data/Experiments/exp1_?

This will apear in rootDir/astrometry_pars/kmt%%%%%%_##


## Generate pickle
Run the plot from the script. Need to be hard-coded.
cd /home/noamse/astro/KMT_ML/code/python/LLutil/
python3 /home/noamse/astro/KMT_ML/code/python/LLutil/run_plotEventPhotAst_from_csv.py
Make it call plotPickleFigWeight.py
will save to 
/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt161221_19/

## Browse Pickles 
Run 
python3 /home/noamse/astro/KMT_ML/code/python/LLutil/browsePicklesPlots.py --dir /home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/


## MATLAB

~/astro/KMT_ML/code/scripts/mlAstrometryResults/plotAstrometryPars.m
Need to hard coded. Will save to

/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt161221_19/


Look at
ml.util.plotAllParams.m (This isn't so useful).
and maybe copy the corner plot. 



## 

So, overall, for each event we have:
/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt161221_19/
/home/noamse/KMT/data/Experiments/Comb_blend_all/astrometry_pars/kmt%%%%%%_##
/home/noamse/KMT/data/Experiments/Comb_blend_all/photometry_outputs/kmt%%%%%%_##


##

tar -czf kmt160576_02_package.tar.gz \
  --transform='s,^.*/,,'
  -T <(
    find /home/noamse/KMT/data/Experiments/Comb_blend_all/astrometry_pars/kmt160576_02 \
         -maxdepth 1 -type f -name "*.png" -print
    find /home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt160576_02 \
         -type f -print
  )
  
  
tar -czf kmt160285_42_blend.tar.gz \
  --transform='s,^.*/,,g' \
  -T <(
    find /home/noamse/KMT/data/Experiments/Comb_blend_all/astrometry_pars/kmt160285_42 \
         -maxdepth 1 -type f -name "*.png" -print
    find /home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt160285_42 \
         -type f -print
  )


"/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_all/plots_summary/kmt160023_42/kmt160023_42_E264_NEP.fig.pkl"

"/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_none/plots_summary/kmt161070_17/kmt161070_17_E267_NEP.fig.pkl"

"/home/noamse/astro/KMT_ML/data/KMTNet/Experiments/Comb_blend_none/plots_summary/kmt161272_21/kmt161272_21_E331_NEP.fig.pkl"




Non significant blending and small pi_E. 

Add lens blending, no all.
all : glen if fix when 'all'




instead run_aux_phot() 
run_phot_mcmc 



			j = LLinit.LLSetup(self.config_2)
			# Still need basic run for aux photometry processing:
			j.run_base()

			# Initialize model for mcmc, with photometric parameters fixed on
			# aux_phot result
			md_mcmc = LLmod.initiate_model(j.Amodel, j.ra, j.dec, plx_par=j.plx_par,
						fixedDict={ 
						% Fix here the astrometry parameters
						't0': j.aux_phot_params_D['t0'],
						'u0': j.aux_phot_params_D['u0'],
						'tE': j.aux_phot_params_D['tE'],
						'mag0': j.aux_phot_params_D['mag0'],
						'fs': j.aux_phot_params_D['fs']},
						tref=np.mean(j.data_arr_P[:,0]),
						lum_blends = j.lum_blends)
			# Setting 'mcmc' parameter value by hand
			mcmc=2
			LLmc.mcmc_wrapper(mcmc, md_mcmc, j.data_arr_A, j.data_arr_P, j.useAstro,
				j.usePhoto, False, j.niter, j.nwalkers, j.plot_results, j.label,
										j.out_path)	


Instead of best, use Std for aux_phot
