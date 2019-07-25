function [OutVec,Rot] = Rotation2D(InVec,q,varargin)

% Rotate 2D vector in angles q. Good for the case where there is an arrays
% of vectors and angles.
% 
% input: 
%         InVec  - the input vector array for rotation.
%                  the size needs to be (numel(q) ,2) [ (x(:),y(:) ]
%         q   - rotation angle array. 
%               deafult units rad. 
% 
% 
% output:
%         OutVec - the rotated vectors array.
%         
%         Rot    - structure array of rotation matrices related to each q
% 


RAD= 180/pi;
DefV.units= 'rad';
InPar = InArg.populate_keyval(DefV,varargin,mfilename);

Rot=[];
if (strcmp(InPar.units,'deg'))
    q=q/RAD; % [deg] 2 [rad]
end

OutVec=zeros(size(InVec'));
for i=1:length(q)
    Rot(i).Mat=[cos(q(i)) -sin(q(i)); sin(q(i)) cos(q(i))];
    OutVec(:,i)=(Rot(i).Mat*InVec(i,:)');
end
end

