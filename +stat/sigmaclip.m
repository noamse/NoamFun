function [ClipingFlag,A] = sigmaclip(A ,Nsigma,varargin)
%	Apply sigma cliping for vector A. 
%   
%   input: 
%
%       A - vector including the data
% 
%       sigma - The multification threshold of the std to clip.



StandartDev = std(A);

ClipingFlag = abs(A - mean(A)) < Nsigma*StandartDev ;
A = A(ClipingFlag);
end

