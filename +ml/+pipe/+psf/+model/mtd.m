function K = mtd(par,Args)

    arguments
        par = [nan,nan,3,3,0,3];
        %Sigma= [3,3,0];
        %beta= 3;
        Args.StampSize=[15,15];
        
    
    end
    
    if isempty(par) || isnan(par(1))||isnan(par(2))
        mu = ceil(Args.StampSize/2);
    else
        mu=par(1:2);
    end
    Sigma= par(3:5);
    beta= par(6);
    [MatX,MatY] = meshgrid( (1:1:Args.StampSize(1)), (1:1:Args.StampSize(2)) );
    
    %K= zeros(Args.StampSize);
    
    
    K = (beta-1)./(pi.*abs((Sigma(1).*Sigma(2) - Sigma(3).^2))) ...
                           .*(1+((MatX-mu(1)).^2./Sigma(1).^2 + ...
                            (MatY-mu(2)).^2./Sigma(2).^2 - ...
                2.*Sigma(3).*(MatX-mu(1)).*(MatY-mu(2))./(Sigma(1).*Sigma(2)))).^(-beta);

    K = K/sum(K(:));
    
    
end