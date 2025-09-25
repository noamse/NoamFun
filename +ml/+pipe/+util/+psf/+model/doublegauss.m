function K = doublegauss(par1,par2,Args)

    arguments
    par1 = [nan,nan,2,2];
    par2 = [nan,nan,2,1];
    Args.StampSize = [15,15];
    end


    if isempty(par1)||isempty(par2) || isnan(par1(1))||isnan(par1(2))||isnan(par2(1))||isnan(par2(2))
        mu1 = ceil(Args.StampSize/2);
        mu2 = ceil(Args.StampSize/2)+ [2,2];
    else
        mu1=par1(1:2);
        mu2=par2(1:2);
    end
    Sigma1 = par1(3);
    f1 = par1(4);
    Sigma2 = par2(3);
    f2 = par2(4);
    
    K = f1.*imUtil.kernel2.gauss(Sigma1,Args.StampSize,mu1)+ f2.*imUtil.kernel2.gauss(Sigma2,Args.StampSize,mu2);
    K=K./sum(K(:));
end
