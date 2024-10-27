function [Npix] = calculateNpix(IF,Args)

arguments
    IF;
    Args.FlagSources = [];
end

[ApixX,ApixY] = IF.generatePixDesignMat;

Wes = calculateWes(IF);

if ~isempty(IF.FlagSourcesPix)
    Wes(:,~IF.FlagSourcesPix)=0;
end
Wes = Wes(:);
OutNan = ~(isnan(ApixX(:,1))| isnan(Wes(:))| isnan(ApixY(:,1)));
Wes = Wes(OutNan,:);ApixX= ApixX(OutNan,:); ApixY= ApixY(OutNan,:);
Npix = (ApixX'*(ApixX.*Wes) + ApixY'*(ApixY.*Wes));
% for Isrc = 1:IF.Nsrc
%      W = Wes(:,Isrc); 
%      Bss(:,:,Isrc)= Bss(:,:,Isrc) + (Ax'*(Ax.*W) + Ay'*(Ay.*W));
% 
% end
% 
% Nss = sparse(Bss(:,:,1));
% 
% for Iblk = 2:numel(Bss(1,1,:)); Nss = blkdiag(Nss,Bss(:,:,Iblk));end
% 
% end
