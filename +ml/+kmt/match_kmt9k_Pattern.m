function [NewX,NewY,PatternMat]= match_kmt9k_Pattern(ImageCat,RefTab,Args)
arguments
    ImageCat
    RefTab
    Args.XCol = 1;
    Args.YCol = 2;
    Args.MagCol = 3; 
    Args.SearchRadius =1;
    Args.MaxMethod = 'max1';
    Args.Step = 0.25;
    Args.Range = [-100.5,100.5]
    Args.MaxMag = 17;
end


RefTabPattern = RefTab(RefTab(:,Args.MagCol)<Args.MaxMag,:);
xyref = RefTabPattern(:,[Args.XCol,Args.YCol]);
xyim = ImageCat.getXY;
[II] = imProc.trans.fitPattern(xyim,xyref,'StepX',Args.Step,'StepY',Args.Step,...
                            'RangeX',Args.Range,'RangeY',Args.Range,'SearchRadius',Args.SearchRadius,'HistRotEdges',(-1:0.001:1),...
                            'MaxMethod',Args.MaxMethod );
                        
PatternMat = II.Sol.AffineTran{1};
[NewX,NewY]=imUtil.cat.affine2d_transformation(RefTab(:,[Args.XCol,Args.YCol]),II.Sol.AffineTran{1},'+'...
                    ,'ColX',1,'ColY',2);
disp('------ Pattern Matched matrix -------')
disp(PatternMat)

end