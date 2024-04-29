function [Xpm,Ypm] = simPM(t,mux,muy,Args)

arguments
    t;
    mux
    muy
    Args.A = 1;
end

if numel(t(:,1))>1
    t= t';
end
if numel(mux(1,:))>1
    mux= mux';
end
if numel(muy(1,:))>1
    muy= muy';
end
%Xpm = zeros(numel(t),numel(mux));
%Ypm = zeros(numel(t),numel(muy));


Xpm = mux*t;
Ypm = muy*t;
end


