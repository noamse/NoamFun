function [SubAstCat ,Edges,SubImCenter]= AstCat_trim(astcat_full,varargin)


% Trim AstCat object by user specified criteria.



DefV.Col ={'XWIN_IMAGE','YWIN_IMAGE'};
DefV.Nsub=[2,4];
DefV.ImSize=[2048,4096];
DefV.new_zero_point= true;
DefV.SubImgSize=[1024,1024];
InPar = InArg.populate_keyval(DefV,varargin,mfilename);


SubAstCat= AstCat(prod(InPar.Nsub));


Edges =  InPar.ImSize ./ InPar.Nsub ;

%for i 
Isub= 1;
SubImCenter= [];
for i = 1:(InPar.Nsub(1))
    for j = 1:(InPar.Nsub(2))
        
        Flag = astcat_full.Cat(:,astcat_full.Col.(InPar.Col{1})) >= (i-1).*Edges(1) &...
            astcat_full.Cat(:,astcat_full.Col.(InPar.Col{1})) < (i).*Edges(1) &...
            astcat_full.Cat(:,astcat_full.Col.(InPar.Col{2})) >= (j-1).*Edges(2) &...
            astcat_full.Cat(:,astcat_full.Col.(InPar.Col{2})) < (j).*Edges(2) ;
        SubAstCat(Isub) = astcat_full;
        SubAstCat(Isub).Cat = SubAstCat(Isub).Cat(Flag,:);
        SubImCenter = [SubImCenter; (i-1).*Edges(1)+Edges(1)/2, (j-1).*Edges(2)+Edges(2)/2];
        
        
        if(InPar.new_zero_point)
            newX = SubAstCat(Isub).Cat(:,SubAstCat(Isub).Col.(InPar.Col{1})) - (i-1).*Edges(1);
            newY = SubAstCat(Isub).Cat(:,SubAstCat(Isub).Col.(InPar.Col{2})) - (j-1).*Edges(1);
            
            SubAstCat(Isub)= col_insert(SubAstCat(Isub),SubAstCat(Isub).Cat(:,SubAstCat(Isub).Col.(InPar.Col{2})),...
                numel(SubAstCat(Isub).ColCell)+1,['Org' InPar.Col{1}]);
            SubAstCat(Isub)= col_insert(SubAstCat(Isub),SubAstCat(Isub).Cat(:,SubAstCat(Isub).Col.(InPar.Col{1})),...
                numel(SubAstCat(Isub).ColCell)+1,['Org' InPar.Col{2}]);
            SubAstCat(Isub).Cat(:,astcat_full.Col.(InPar.Col{1})) = newX;
            SubAstCat(Isub).Cat(:,astcat_full.Col.(InPar.Col{2})) = newY;
        end
        
        Isub=Isub+1;
    end
end

end
   
