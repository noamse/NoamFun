function updateParAnnual(IF)


IF.ParA = IF.ParA+ reshape(IF.epsA,size(IF.ParA,1),size(IF.ParA,2));
end 