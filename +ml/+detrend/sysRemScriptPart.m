function [ObjSys,sysCorX,sysCorY]= sysRemScriptPart(IF,Obj,Args)


arguments
    IF; 
    Obj
    Args.NIter = 5;
    Args.UseWeight = true;
end


[RxOrg,RyOrg] = IF.calculateResiduals;
Wes = calculateWes(IF);
if Args.UseWeight
    Sigma = sqrt(1./Wes);Sigma(isnan(Sigma)) = Inf;
else
    Sigma = ones(size(RxOrg));
end

%Csys =C;
%Csys(isnan(Csys))=0;
%[AxSys,SysRemX]= timeSeries.detrend.sysrem(RxOrg,Sigma,'Niter',3,'A',Csys-median(Csys),'C',IF.Data.fwhm(:,1));
%[AySys,SysRemY]= timeSeries.detrend.sysrem(RyOrg,Sigma,'Niter',3,'A',Csys-median(Csys),'C',IF.Data.fwhm(:,1));
[~,SysRemX]= timeSeries.detrend.sysrem(RxOrg,Sigma,'Niter',Args.NIter);
[~,SysRemY]= timeSeries.detrend.sysrem(RyOrg,Sigma,'Niter',Args.NIter);


ObjSys = Obj.copy();
sysCorX = zeros(size(SysRemX(end).A.* SysRemX(end).C));
sysCorY = zeros(size(SysRemY(end).A.* SysRemY(end).C));
Csys=zeros(size(SysRemY(end).C));
Asys = zeros(size(SysRemY(end).A));
for Isys = 2:numel(SysRemX)
    sysCorX = sysCorX+ SysRemX(Isys).A.* SysRemX(Isys).C;
    sysCorY = sysCorY+ SysRemY(Isys).A.* SysRemY(Isys).C;
    Csys = Csys + SysRemY(Isys).C;
    Asys = Asys + SysRemY(Isys).A;

end
ObjSys.Data.X = ObjSys.Data.X -sysCorX;
ObjSys.Data.Y = ObjSys.Data.Y -sysCorY;

