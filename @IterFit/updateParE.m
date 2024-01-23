function updateParE(IF)


IF.ParE = IF.ParE+ reshape(IF.epsE,size(IF.ParE,1),size(IF.ParE,2));
end 