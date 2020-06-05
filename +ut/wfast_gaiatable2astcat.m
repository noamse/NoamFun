function GAIACat= wfast_gaiatable2astcat(CatTable)
% Read WFAST GAIA catalogs saved in table format into AstCat object
GAIACat= AstCat;
GAIACat.Cat = table2array(CatTable);
GAIACat.ColCell =  CatTable.Properties.VariableNames;
GAIACat = colcell2col(GAIACat);




end