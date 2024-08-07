function path= fullpath(dirobj,ind,varargin)
% The function returns the full path of the ind's (ind) element in the dirobj (matlab dir object).
% Directory are default
InPar = inputParser;
addOptional(InPar,'IsFile',false);  % Default is path to directory
addOptional(InPar,'CutDropbox',false);  % Default is path to directory
parse(InPar,varargin{:});
InPar = InPar.Results;


path= fullfile(dirobj(ind).folder,dirobj(ind).name);
if ~InPar.IsFile
    path=[path '/'];
end
if InPar.CutDropbox
    path = erase(path,'/Dropbox (Weizmann Institute)');
    path = strrep(path,'data1','home');
end