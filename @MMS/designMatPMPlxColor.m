function [H]  = designMatPMPlxColor(Obj,Color,Coo,Args)

arguments 
    Obj;
    Color; 
    Coo;
    Args.JD=[];
    Args.JD0 = 0;
    Args.EarthCoo = [];
    Args.C0 = 0;
end



if isempty(Args.JD)
    JD = Obj.JD;
else
    JD = Args.JD;
end




if isempty(Args.EarthCoo)
    [Ecoo] = celestial.SolarSys.calc_vsop87(JD, 'Earth', 'e', 'E');
else
    Ecoo = Args.EarthCoo;
end
X = Ecoo(1,:)'; Y = Ecoo(2,:)'; Z = Ecoo(3,:)';


JD=JD-Args.JD0;

% if isempty(Args.Coo)
%     RA = Obj.medianFieldSource({'RA'});
%     Dec = Obj.medianFieldSource({'Dec'});
% else
%     RA = Args.Coo(:,1);
%     Dec = Args.Coo(:,2);
% end
RA = Coo(:,1);
Dec= Coo(:,2);

Cbar = Color(1)-Args.C0;

Hpm = designMatrixPM(Obj);
Hzero= zeros(size(Hpm));
PA= Obj.getTimeSeriesField(1,{'pa'});

RAPlxTerm= -1/400*(X.*sin(RA(1))- Y.*cos(RA(1))); 
DecPlxTerm= 1/400*(X.*cos(RA(1)).*sin(RA(1)) + Y.*sin(RA(1)).*sin(Dec(1)) - Z.*cos(Dec(1))) ; 

if ~all(Color==0)
ColorTermSin = 1/400*Cbar.*sin(PA);
ColorTermCos = 1/400*Cbar.*cos(PA);

H = [Hpm,Hzero,RAPlxTerm,ColorTermSin,ColorTermCos;Hzero,Hpm,DecPlxTerm,ColorTermSin,ColorTermCos];
else
    H = [Hpm,Hzero,RAPlxTerm;Hzero,Hpm,DecPlxTerm];
    
end

end


