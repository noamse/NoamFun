function [Xch,Ych,PA,C] = simChrom(RefractionAmp,C,PA,Args)

arguments
    RefractionAmp;
    C;
    PA;
    Args.AxisRot=[1,0;0,1]; %default is Y towars north, X towards West (?)
end

if (RefractionAmp(:,1))>1
    RefractionAmp=RefractionAmp';
end

if numel(PA(:,1))>1
    PA= PA';
end
if numel(C(1,:))>1
    C= C';
end


Xch=  -C* (RefractionAmp.*sin(PA));
Ych=  C* (RefractionAmp.*cos(PA));
%Xch=  C* (RefractionAmp.*sin(PA)).* Args.AxisRot(1,1) + C* (RefractionAmp.*cos(PA)).* Args.AxisRot(1,2);
%Ych=  C*(RefractionAmp.*sin(PA)).* Args.AxisRot(2,1) + C* (RefractionAmp.*cos(PA)).* Args.AxisRot(2,2);



