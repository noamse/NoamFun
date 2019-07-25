function astcatout= compare_cat(matchdata,varargin)

DefV.RAfield = 'ALPHAWIN_J2000';
DefV.Decfield = 'DELTAWIN_J2000';
DefV.CatName= 'GAIADR2';
DefV.searchRadius = 1;

InPar = InArg.populate_keyval(DefV,varargin,mfilename);



astcatout=catsHTM.cone_search(InPar.CatName,0,0,InPar.searchRadius,'OutType','astcat');
astcatout.Cat = [];

Nobject = numel(matchdata.ALPHAWIN_J2000(:,1));

for ObjectInd=1:Nobject
    RAGAIAcone=nanmean(matchdata.ALPHAWIN_J2000(ObjectInd,1));
    DecGAIAcone=nanmean(matchdata.DELTAWIN_J2000(ObjectInd,1));
    [conecat,~,~]=catsHTM.cone_search(InPar.CatName,RAGAIAcone,DecGAIAcone,InPar.searchRadius);     
    Gaiasize=size(conecat);
    if ~(Gaiasize(1)== 1)
        conecat=nan(1,Gaiasize(2));
    end
    astcatout.Cat = [astcatout.Cat ; conecat];

end