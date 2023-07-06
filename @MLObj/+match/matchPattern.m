function matchPattern(MO,Args)
% Match pattren of the AstroCatalog array with respect to the
% reference catalog.  

arguments
    CM;
    Args.SearchRadius =1.5;
    Args.MaxMethod = 'max1';
    Args.Step = 0.05;
    Args.Range = [-5.5,5.5]
    Args.MaxMag = [];
    Args.RotationEdges = (-5:0.01:5);
end


% Clip sources by reference mag
if ~isempty(Args.MaxMag)
    flagMagRef = MO.RefCat.getCol(MO.RefMagColName)<Args.MaxMag;
    xyref= MO.RefCat.getCol({'X','Y'});
    xyref = xyref(flagMagRef,:);
end

% Go over cat and fit for the best transformation w.r.t RefCat
for IndCat = 1:numel(MO.AstCat)
    try
        if ~isempty(Args.MaxMag)
            
            flagMaAstCat= MO.AstCat(IndCat).getCol(MO.RefMagColName)<Args.MaxMag;
            xyastcat = MO.AstCat(IndCat).getCol({'X','Y'});
            [II] = imProc.trans.fitPattern(xyref,xyastcat(flagMaAstCat,:),'StepX',Args.Step,'StepY',Args.Step,...
                'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',Args.RotationEdges,...
                'MaxMethod',Args.MaxMethod );
            
            
            
            
        else
            
            
            [II] = imProc.trans.fitPattern(MO.RefCat,MO.AstCat(IndCat),'StepX',Args.Step,'StepY',Args.Step,...
                'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',(-90:0.2:90),...
                'MaxMethod',Args.MaxMethod );
            [NewX,NewY]=imUtil.cat.affine2d_transformation(MO.AstCat(IndCat).Catalog,II.Sol.AffineTran{1},'+'...
                ,'ColX',MO.AstCat(IndCat).colname2ind('X'),'ColY',MO.AstCat(IndCat).colname2ind('Y'));
        end
        MO.PatternMat{IndCat} =II.Sol.AffineTran;
    catch
        MO.Pattern_failed= [MO.Pattern_failed,IndCat];
        MO.PatternMat{IndCat}= {};
    end
end


end