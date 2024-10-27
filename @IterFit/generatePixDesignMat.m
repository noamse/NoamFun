function [ApixX,ApixY] = generatePixDesignMat(IF,Args)

arguments
    IF;
    Args.FlagSources = [];
end

%Zeros = zeros([IF.Nepoch],1);

Xphase  = IF.Data.Xphase(:);
Yphase  = IF.Data.Yphase(:);
ApixX = [Xphase,Xphase.^2,Xphase.^3,Xphase.^4,Xphase.^5];
ApixY=  [Yphase  Yphase  .^2,Yphase.^3,Yphase.^4,Yphase.^5];


ZEROS = zeros(size(ApixX));
ApixX = [ApixX,ZEROS];
ApixY = [ZEROS,ApixY];