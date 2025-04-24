function [NC,edgesC,binC] = generateBins(IF,Args)

arguments
    IF;
    Args.CBinWidth=[];
    Args.ClearBadColor = true;
    Args.nBins = 6;
end

% if ~isempty(Args.CBinWidth)
%     CBinWidth = Args.CBinWidth;
% else
%     CBinWidth =IF.CBinWidth;
% end
% 
% 
% [NC,edgesC,binC] = histcounts(IF.Data.C(1,:)','BinWidth',CBinWidth);
% 
% if Args.ClearBadColor 
%     binC(IF.Data.C(1,:)'<-9)=0;
% end
% 
% 
% end

C = IF.Data.C(1,:)';

% Desired number of bins


% Compute bin edges using quantiles
edgesC = quantile(C, linspace(0, 1, Args.nBins + 1));

% Assign data to bins
binC = discretize(C, edgesC);

% Optional: count elements in each bin
NC = accumarray(binC(~isnan(binC)), 1);