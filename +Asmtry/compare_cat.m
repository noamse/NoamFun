function astcatout= compare_cat(matchdata,varargin)

DefV.RAfield = 'ALPHAWIN_J2000';
DefV.Decfield = 'DELTAWIN_J2000';
DefV.CatName= 'GAIADR2';
DefV.Units='rad';
DefV.searchRadius = 0.5;

InPar = InArg.populate_keyval(DefV,varargin,mfilename);



astcatout=catsHTM.cone_search(InPar.CatName,0,0,InPar.searchRadius,'OutType','astcat');
astcatout.Cat = [];

Nobject = numel(matchdata.ALPHAWIN_J2000(:,1));

for ObjectInd=1:Nobject
    switch InPar.Units
        case 'rad'
            RAGAIAcone=nanmean(matchdata.ALPHAWIN_J2000(ObjectInd,1));
            DecGAIAcone=nanmean(matchdata.DELTAWIN_J2000(ObjectInd,1));
        case 'deg'
            RAGAIAcone=nanmean(matchdata.ALPHAWIN_J2000(ObjectInd,1))*pi/180;
            DecGAIAcone=nanmean(matchdata.DELTAWIN_J2000(ObjectInd,1))*pi/180;
    end
    
    [conecat,~,~]=catsHTM.cone_search(InPar.CatName,RAGAIAcone,DecGAIAcone,InPar.searchRadius);     
    Gaiasize=size(conecat);
    if ~(Gaiasize(1)== 1)
        conecat=nan(1,Gaiasize(2));
    end
    astcatout.Cat = [astcatout.Cat ; conecat];

end