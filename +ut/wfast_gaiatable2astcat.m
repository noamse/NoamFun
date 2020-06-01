function GAIACat= wfast_gaiatable2astcat(CatTable)

GAIACat= AstCat;
GAIACat.Cat = table2array(CatTable);
GAIACat.ColCell =  CatTable.Properties.VariableNames;
GAIACat = colcell2col(GAIACat);




end