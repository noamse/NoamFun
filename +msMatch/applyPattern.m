function Cats= applyPattern(Cats,PatternMat,Args)

arguments
    Cats;
    PatternMat;
    Args.ColNameX = 'X'
    Args.ColNameY = 'Y'
end
%Cats= Obj.Cats;
for Icat = 1:numel(Cats)
    [NewX,NewY]=imUtil.cat.affine2d_transformation(Cats(Icat).getCol({Args.ColNameX,Args.ColNameY}),PatternMat{Icat},'+'...
        ,'ColX',1,'ColY',2);
    Cats(Icat).Catalog(:,Cats(Icat).colname2ind(Args.ColNameX)) = NewX;
    Cats(Icat).Catalog(:,Cats(Icat).colname2ind(Args.ColNameY)) = NewY;
    
    
    
end



