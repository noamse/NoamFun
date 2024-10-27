function updateParPix(IF)


IF.ParPix = IF.ParPix+ reshape(IF.epsPix,size(IF.ParPix,1),size(IF.ParPix,2));

end 