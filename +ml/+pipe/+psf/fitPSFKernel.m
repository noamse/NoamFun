function [a,Kmin] = fitPSFKernel(PSF,Args)

arguments
    PSF
    Args.p0 = [] ;
    Args.model = 'mtd'
    Args.ConvThresh = 1e-4
    Args.StampSize = size(PSF);
    Args.FitRadius = [];
    Args.FitWings = false;
    Args.InerRadius= [];
end



if Args.FitWings
    switch Args.model
        case 'mtd'
            %K=mtd([nan,nan,2,2,-0.1,2],'StampSize',Args.StampSize);
            
            w= 1./PSF.^2;
            if isempty(Args.p0)
                x0 = [Args.StampSize(1)/2,Args.StampSize(2)/2,4,4,-1e-3,4];
            else
                x0 = Args.p0;
            end
            if ~isempty(Args.FitRadius)
                Args.FitRaidus = 6;
            end
            
            
            if isempty(Args.InerRadius)
                Args.InerRadius = 0;
            end
            
           
            VecXrel = (1:1:Args.StampSize(1)) - x0(1);
            VecYrel = (1:1:Args.StampSize(2)) - x0(2);
            [matx,maty]= meshgrid(VecXrel,VecYrel);
            Rrel2 = matx.^2+maty.^2;
            
            fit_region_flag = Rrel2<Args.FitRadius.^2 & Rrel2>Args.InerRadius.^2 ;
            
            func_min = @(x) mtd_func_min(x,PSF,Args.StampSize, fit_region_flag,w);
            a  = fminsearch(func_min ,x0);
            Kmin = mtd(a,'StampSize',Args.StampSize);
            meas_region_flag = Rrel2>Args.FitRadius.^2;
            Kmin(~meas_region_flag) = PSF(~meas_region_flag);
            
            
        case 'gauss'
            w= 1./PSF.^2;
            if isempty(Args.p0)
                x0 = [4,Args.StampSize(1)/2,Args.StampSize(2)/2];
            else
                x0 = Args.p0;
            end
            
            if ~isempty(Args.FitRadius)
                Args.FitRaidus = 6;
            end

            
            if isempty(Args.InerRadius)
                Args.InerRadius = 0;
            end
            
            
           
            VecXrel = (1:1:Args.StampSize(1)) - x0(2);
            VecYrel = (1:1:Args.StampSize(2)) - x0(3);
            [matx,maty]= meshgrid(VecXrel,VecYrel);
            Rrel2 = matx.^2+maty.^2;
            
            fit_region_flag = Rrel2<Args.FitRadius.^2 & Rrel2>Args.InerRadius.^2 ;
            func_min = @(x) gauss_func_min(x,PSF,Args.StampSize, fit_region_flag,w);
            %K = imUtil.kernel2.gauss(x0(1),Args.StampSize,x0(2:3));
            %imUtil.kernel2.gauss(Sigma,SizeXY,PosXY)
            %func_min = @(x) sum(abs(imUtil.kernel2.gauss(x(1),Args.StampSize,x(2:3)) - PSF).^2./w,'all');
            a  = fminsearch(func_min,x0);
            Kmin = imUtil.kernel2.gauss(a(1),Args.StampSize,a(2:3));
            meas_region_flag = Rrel2>Args.FitRadius.^2;
            Kmin(~meas_region_flag) = PSF(~meas_region_flag);
            
            
            
        case 'dgauss'
            w= abs(1./PSF);
            if isempty(Args.p0)
                x0 = [4,Args.StampSize(1)/2,Args.StampSize(2)/2,0.7;2,Args.StampSize(1)/2-0.5,Args.StampSize(2)/2+0.5,0.1];
            else
                x0 = Args.p0;
            end
            %K = imUtil.kernel2.gauss(x0(1),Args.StampSize,x0(2:3));
            if ~isempty(Args.FitRadius)
                Args.FitRaidus = 6;
            end
            
            
            if isempty(Args.InerRadius)
                Args.InerRadius = 0;
            end

            %imUtil.kernel2.gauss(Sigma,SizeXY,PosXY)
            if ~isempty(Args.FitRadius)
                VecXrel = (1:1:Args.StampSize(1)) - x0(1,2);
                VecYrel = (1:1:Args.StampSize(2)) - x0(1,3);
                [matx,maty]= meshgrid(VecXrel,VecYrel);
                Rrel2 = matx.^2+maty.^2;
                fit_region_flag = Rrel2<Args.FitRadius.^2 & Rrel2>Args.InerRadius.^2 ;
            else
                fit_region_flag = true(size(PSF));
            end
            

            
            func_min = @(x) dgauss_func_min(x,PSF,Args.StampSize, fit_region_flag,w);
            a  = fminsearch(func_min,x0);
            Kmin = doublegauss(a(1,:),a(2,:),'StampSize',Args.StampSize);
            meas_region_flag = Rrel2>Args.FitRadius.^2;
            Kmin(~meas_region_flag) = PSF(~meas_region_flag);
    end
    
    
    
    
    
    
    
else
    switch Args.model
        case 'mtd'
            K=mtd([nan,nan,2,2,-0.1,2],'StampSize',Args.StampSize);
            
            w= 1./PSF.^2;
            if isempty(Args.p0)
                x0 = [Args.StampSize(1)/2,Args.StampSize(2)/2,4,4,-1e-3,4];
            else
                x0 = Args.p0;
            end
            if ~isempty(Args.FitRadius)
                VecXrel = (1:1:Args.StampSize(1)) - x0(1);
                VecYrel = (1:1:Args.StampSize(2)) - x0(2);
                [matx,maty]= meshgrid(VecXrel,VecYrel);
                Rrel2 = matx.^2+maty.^2;
                fit_region_flag = Rrel2<Args.FitRadius.^2;
            else
                fit_region_flag = true(size(PSF));
            end
            func_min = @(x) mtd_func_min(x,PSF,Args.StampSize, fit_region_flag,w);
            a  = fminsearch(func_min ,x0);
            Kmin = mtd(a,'StampSize',Args.StampSize);
            
            
        case 'gauss'
            w= 1./PSF.^2;
            if isempty(Args.p0)
                x0 = [4,Args.StampSize(1)/2,Args.StampSize(2)/2];
            else
                x0 = Args.p0;
            end
            
            func_min = @(x) sum(abs(imUtil.kernel2.gauss(x(1),Args.StampSize,x(2:3)) - PSF).^2./w,'all');
            a  = fminsearch(func_min,x0);
            Kmin = imUtil.kernel2.gauss(a(1),Args.StampSize,a(2:3));
            
            
            
        case 'dgauss'
            w= abs(1./PSF);
            if isempty(Args.p0)
                x0 = [4,Args.StampSize(1)/2,Args.StampSize(2)/2,0.7;0.5,Args.StampSize(1)/2-2,Args.StampSize(2)/2+2,0.1];
            else
                x0 = Args.p0;
            end
            
            if ~isempty(Args.FitRadius)
                VecXrel = (1:1:Args.StampSize(1)) - x0(1,2);
                VecYrel = (1:1:Args.StampSize(2)) - x0(1,3);
                [matx,maty]= meshgrid(VecXrel,VecYrel);
                Rrel2 = matx.^2+maty.^2;
                fit_region_flag = Rrel2<Args.FitRadius.^2;
            else
                fit_region_flag = true(size(PSF));
            end
            
            func_min = @(x) dgauss_func_min(x,PSF,Args.StampSize, fit_region_flag,w);
            a  = fminsearch(func_min,x0);
            Kmin = doublegauss(a(1,:),a(2,:),'StampSize',Args.StampSize);
    end
end

end



function V = mtd_func_min(x,PSF,StampSize, fit_region_flag,w)
    

    K = mtd(x,'StampSize',StampSize);
    V =sum(abs(K(fit_region_flag) - PSF(fit_region_flag)).^2./w(fit_region_flag),'all');

end


function V = dgauss_func_min(x,PSF,StampSize, fit_region_flag,w)
    

    K = doublegauss(x(1,:),x(2,:),'StampSize',StampSize);
    V =sum(abs(K(fit_region_flag) - PSF(fit_region_flag)).^2./w(fit_region_flag),'all');

end



function V = gauss_func_min(x,PSF,StampSize, fit_region_flag,w)
    

    K = imUtil.kernel2.gauss(x(1),StampSize,x(2:3));
    V =sum(abs(K(fit_region_flag) - PSF(fit_region_flag)).^2./w(fit_region_flag),'all');

end
