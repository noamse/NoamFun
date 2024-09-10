function Cats= imageReduction(SA,Args)

arguments
    SA;
    Args.HalfSize= 7 ; 
    Args.ImagePath=  '/home/noamse/KMT/data/simulations/simulatedIM/'
    Args.AstCatPath = '/home/noamse/KMT/data/simulations/simulatedCat/'
end



A= load([SA.ImageTargetFolder],'RefCat.mat');
RefCat= A.RefCat;










