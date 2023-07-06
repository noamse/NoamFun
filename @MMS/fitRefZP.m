function ZP = fitRefZP(Obj,Args)
arguments
    Obj;
    Args.ZPFun = @tools.math.stat.rmean;
    Args.ColNameMag = 'MAG_PSF';
    Args.ColNameRefMag = 'RefMag';
end
ZP= zeros(Obj.Nepoch,1);
for Iepoch = 1:numel(Obj.JD)
    
    %Result = imProc.match.matchReturnIndices(AstroCatalog({[CM.MS.Data.X(EpochInd,:)',CM.MS.Data.Y(EpochInd,:)']},'ColNames',{'X','Y'}),CM.OgleCat,'Radius',Args.MatchRadius);

    %CM.zp(EpochInd) = tools.math.stat.rmean(CM.MS.Data.MAG_PSF(EpochInd,CM.matched_flag_ref_cat)' - ogleI(CM.matched_flag_ogle_cat),1);
    [H] = Obj.designMatrixEpoch(Iepoch,{Args.ColNameMag,Args.ColNameRefMag}, {1,1});
    ZP(Iepoch) = Args.ZPFun(H(:,1)-H(:,2),1);
end
%ZP=reshape(CM.zp,[numel(CM.zp),1]) ;