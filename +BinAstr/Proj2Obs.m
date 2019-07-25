function [Vectag] = Proj2Obs(Vec,Long,Lat)
% Calculating the 3d vector projection of target at Long,Lat as seen in the
% observer;
% input:
%       Long,Lat - Longtiude, Latitude [radians]
%                  ecliptic longitude and latitude of the 
%                  target's apparent position
% 
%output:
%       X,Y  - the 3d vector projection to observer plane where X is
%              sits on the ecliptic plane


eul=[-(pi/2+Lat),zeros(size(Long)),Long];
%rotm = eul2rotm(eul,'XYZ');
%rotm = eul2rot_XYZ(eul);
Vectag=zeros(size(Vec));
for i=1:numel(Long)
    %Vectag(:,i)=rotm(:,:,i)*Vec(i,:)';
    ct= cos(eul(i,:));
    st = sin(eul(i,:));
    Vectag(i,1) = [ct(2).*ct(3), -ct(2).*st(3),st(2)]*Vec(i,:)';
    Vectag(i,2) = [ct(1).*st(3) + ct(3).*st(1).*st(2), ct(1).*ct(3) - st(1).*st(2).*st(3),-ct(2).*st(1)]*Vec(i,:)';
    Vectag(i,3) = [st(1).*st(3) - ct(1).*ct(3).*st(2), ct(3).*st(1) + ct(1).*st(2).*st(3),ct(1).*ct(2)]*Vec(i,:)';
%    R = eul2rot_XYZ_3d(eul(i,:));
%    Vectag(:,i)=R*Vec(i,:)';
end

%Vectag=Vectag';

end

%{
function R = eul2rot_XYZ( eul, varargin )
    

% using the eul2rotm matlab function for the case of 'XYZ' squence, without
% the validation of the input
    R = zeros(3,3,size(eul,1));
    ct = cos(eul);
    st = sin(eul);

    R(1,1,:) = ct(:,2).*ct(:,3);
    R(1,2,:) = -ct(:,2).*st(:,3);
    R(1,3,:) = st(:,2);
    R(2,1,:) = ct(:,1).*st(:,3) + ct(:,3).*st(:,1).*st(:,2);
    R(2,2,:) = ct(:,1).*ct(:,3) - st(:,1).*st(:,2).*st(:,3);
    R(2,3,:) = -ct(:,2).*st(:,1);
    R(3,1,:) = st(:,1).*st(:,3) - ct(:,1).*ct(:,3).*st(:,2);
    R(3,2,:) = ct(:,3).*st(:,1) + ct(:,1).*st(:,2).*st(:,3);
    R(3,3,:) = ct(:,1).*ct(:,2);


end

function R = eul2rot_XYZ_3d( eul, varargin )
    

% using the eul2rotm matlab function for the case of 'XYZ' squence, without
% the validation of the input
    R = zeros(3,3);
    ct = cos(eul);
    st = sin(eul);

    R(1,1) = ct(2).*ct(3);
    R(1,2) = -ct(2).*st(3);
    R(1,3) = st(2);
    R(2,1) = ct(1).*st(3) + ct(3).*st(1).*st(2);
    R(2,2) = ct(1).*ct(3) - st(1).*st(2).*st(3);
    R(2,3) = -ct(2).*st(1);
    R(3,1) = st(1).*st(3) - ct(1).*ct(3).*st(2);
    R(3,2) = ct(3).*st(1) + ct(1).*st(2).*st(3);
    R(3,3) = ct(1).*ct(2);


end
%}