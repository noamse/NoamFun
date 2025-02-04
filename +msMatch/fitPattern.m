function [Result] = fitPattern(Cats,Args)
arguments
    Cats;
    Args.SearchRadius =1;
    Args.MaxMethod = 'max1';
    Args.MaxRefMag = [];
    Args.ColNameRefMag = 'RefMag';
    Args.ColNameX = 'X';
    Args.ColNameY = 'Y';
    Args.ColNameRefX = 'RefX';
    Args.ColNameRefY = 'RefY';
    Args.RefCat      = [];     % AstroCatalog with reference position in first two columns. 
    Args.Scale                   = 1.0; % scale or [min max] range that require to ?
    Args.HistDistEdgesRotScale   = [10 600 300];
    Args.HistDistEdgesRot        = (12:3:100).';
    Args.HistRotEdges            = (-1:0.5:1);  % rotation or [min max] rotation that require to ?
    Args.RangeX                  = [-16 16];
    Args.RangeY                  = [-16 16];
    Args.StepX                   = 0.2;
    Args.StepY                   = 0.2;
    Args.Flip                    = [1 1];
    
    
    % maxima finding
    Args.Threshold               = 5;
    Args.FracOfMax               = 0.8;
    Args.Conn                    = 8;
    Args.Overlap                 = [16];
    Args.SubSizeXY               = [1024,1024];
    Args.MinVariance             = 1;
    Args.FilterSigma             = 3;
    
end

if ~isempty(Args.RefCat) & isa(Args.RefCat,'AstroCatalog')
    RefCat = Args.RefCat; 
else

    RefCat = AstroCatalog({Cats(1).getCol({Args.ColNameRefX,Args.ColNameRefY})},'ColNames',{Args.ColNameRefX,Args.ColNameRefY});
end
% match catalogs
if nargout>1
    OutputArgs = cell(1,3);
    Nargs = 3;
else
    OutputArgs = cell(1,1);
    Nargs = 1;
end

if ~isempty(Args.MaxRefMag)
    FlagMagRef = Cats(1).getCol(Args.ColNameRefMag )< Args.MaxRefMag;
    RefCat.Catalog(FlagMagRef,:) = nan;
end

for IndCat = 1:numel(Cats)
    [OutputArgs{1:Nargs}] = imUtil.patternMatch.match_scale_rot_shift(RefCat.Catalog, Cats(IndCat).getCol({Args.ColNameX,Args.ColNameY}),...
        'CatColX',1, 'CatColY',2,...
        'RefColX',1, 'RefColY',2,...
        'Scale',1,...
        'HistDistEdgesRotScale',Args.HistDistEdgesRotScale,...
        'HistDistEdgesRot',Args.HistDistEdgesRot,...
        'HistRotEdges',Args.HistRotEdges,...
        'RangeX',Args.RangeX,...
        'RangeY',Args.RangeY,...
        'StepX',Args.StepX,...
        'StepY',Args.StepY,...
        'Flip',Args.Flip,...
        'SearchRadius',Args.SearchRadius,...
        'MaxMethod',Args.MaxMethod,...
        'Threshold',Args.Threshold,...
        'FracOfMax',Args.FracOfMax,...
        'Conn',Args.Conn,...
        'SubSizeXY',Args.SubSizeXY,...
        'Overlap',Args.Overlap,...
        'MinVariance',Args.MinVariance,...
        'FilterSigma',Args.FilterSigma);
    
        
        if ~isfield(OutputArgs{1},'AffineTran') || ~isfield(OutputArgs{1},'AffineTranNoFlip')
            OutputArgs{1}.AffineTran = {0};
            OutputArgs{1}.AffineTranNoFlip = {0};
        end
        
        Result(IndCat)  = OutputArgs{1};
        

    
    %'VarFun',Args.VarFun,...
        %'VarFunPar',Args.VarFunPar,...
        %'BackFun',Args.BackFun,...
        %'BackFunPar',Args.BackFunPar,...
    
    %{
    [II] = imProc.trans.fitPattern(CM.RefCat,CM.AstCat(IndCat),'StepX',Args.Step,'StepY',Args.Step,...
        'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',(-90:0.2:90),...
        'MaxMethod',Args.MaxMethod );
    [NewX,NewY]=imUtil.cat.affine2d_transformation(CM.AstCat(IndCat).Catalog,II.Sol.AffineTran{1},'+'...
        ,'ColX',CM.AstCat(IndCat).colname2ind('X'),'ColY',CM.AstCat(IndCat).colname2ind('Y'));
end
        %}
end
