function Files = read_dir_names ( Directory,varargin)
%{
Reading the filenames from directory
Input: 
        Directory - Directory path/name

options:
        'type' - type of files to be read
        
        'sortFlag' - sort by numbers appear in the file names.
                     deafult is false
        
        'TextBefSort' - specified the text that appear befor the numbers
                           that need to be sorted 
                           deafult is ''.
        'TextAftSort' - same for text after
                           deafult is file type.

        
%}

DefV.type='*';
DefV.sortFlag = false;
DefV.TextBefSort = '';
DefV.TextAftSort = '';

InPar = InArg.populate_keyval(DefV,varargin,mfilename);
if (isempty(InPar.TextAftSort))
   InPar. TextAftSort = InPar.type;
end

A= dir([Directory '*' InPar.type]); 
Files= {A(:).name};
if InPar.sortFlag
    str  = sprintf('%s#', Files{:});
    num  = sscanf(str, [InPar.TextBefSort '%d' InPar.TextAftSort '#']);
    [~, index] = sort(num);
    Files = Files(index);
end

end
