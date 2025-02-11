function [DirCell,JD]= generateDirCell(Args)
arguments
    Args.BaseDir = '/data1/noamse/KMT/images/ob190506/';
    Args.Site = 'CTIO';
    Args.FileExt = 'fits';
    Args.Filter='I';
    Args.JDkey='MIDJD';
    Args.KASIFormat = true;
end

if Args.KASIFormat 
    DirList     = dir(fullfile([Args.BaseDir '*/'], ['*' Args.FileExt]));
    
else
    DirList     = dir(fullfile([Args.BaseDir], ['*' Args.FileExt]));
end
DirCell =cell(size(DirList));
telescope=cell(size(DirList));
JD = zeros(size(DirList));

for Ifile=1:numel(DirList)
    
    DirCell{Ifile} = ut.fullpath(DirList,Ifile,'IsFile',true);
    H = AstroHeader(DirCell{Ifile});
    Filter = H.getVal('FILTER');
    JD(Ifile) = H.getVal(Args.JDkey);
    telescope{Ifile}= H.Key.OBSERVAT;
    if ~strcmp(Filter,Args.Filter)
        DirCell{Ifile} = [] ;
    end
    
end
dircell_flag = cellfun(@isempty,DirCell);
if isempty(Args.Site)
    telescope_flag= true(size(telescope ));
else
    telescope_flag =strcmp(telescope,Args.Site);
end
flag = dircell_flag | ~telescope_flag | isnan(JD);
DirCell(flag ) = [];
JD(flag ) = [];
[JD,ind_sort_jd] = sort(JD);
DirCell=  DirCell(ind_sort_jd); 
end