function RefTab = read_kmt9k_cat(imagePath,Args)
arguments  
    imagePath;
    Args.CatalogDir = '/home/noamse/KMT/data/Catalogs/';
    Args.XCol = 1;
    Args.YCol = 2;
    Args.MagCol = 3; 
    Args.SearchRadius =1;
    Args.MaxMethod = 'max1';
    Args.Step = 0.25;
    Args.Range = [-100.5,100.5]
    Args.MaxMag = 19;
    Args.Ncols = 12; 
    Args.Verbose = true;
end


Header= AstroHeader(imagePath);
ccdname = Header.getVal('CCDNAME');
ccdname = split(ccdname );
ccdname = ccdname{end};
fieldname = Header.getVal('OBJECT');
history_str = Header.getVal('HISTORY');
CCDSEC= str2double(split(history_str,{'[',':',',',']'}));
CCDSEC(isnan(CCDSEC)) = [];

catpath = dir([Args.CatalogDir,fieldname,ccdname,'*']);
catpath  =ut.fullpath(catpath,1,'IsFile',true) ;

%RefTab = load(catpath);

len = 5000;

%CellOut = cell(len,1);
%EmptyCell= cell(len,1);
ipart = 0;
fid = fopen(catpath, 'r');


if fid < 0, error('Cannot open file'); end
while 1  % Infinite loop
  s = fgets(fid);
  if ischar(s)
    data = sscanf(s, '%g %g %g', [3 1]);
    if data(1)>CCDSEC(1) && data(1)<CCDSEC(2) &&...
            data(2)>CCDSEC(3) && data(2)<CCDSEC(4) && data(3)<Args.MaxMag
      ipart = ipart + 1;
      if ipart==1
          FirstRow= str2num(s);
          RefTab=zeros(len,numel(FirstRow));
          RefTab(1,:)= FirstRow;
      else
        %CellOut{ipart} = s;
        RefTab(ipart,:)= str2num(s);
      end

      if mod(ipart,len)==0
        %CellOut= [CellOut;EmptyCell];
        RefTab =  [RefTab;zeros(len,numel(FirstRow))];
      end
    end
  else  % End of file:
    break;
  end
end
fclose('all');
% flag = RefTab(:,Args.XCol) >= CCDSEC(1) &RefTab(:,Args.XCol) <= CCDSEC(2) ...
%     & RefTab(:,Args.YCol) >= CCDSEC(3) &RefTab(:,Args.YCol) <= CCDSEC(4) ...
%     & RefTab(:,Args.MagCol) <Args.MaxMag;
%RefTab = RefTab(flag,:);
RefTab = RefTab(any(RefTab,2),:);
RefTab(:,[Args.XCol,Args.YCol]) = RefTab(:,[Args.XCol,Args.YCol]) - [CCDSEC(1),CCDSEC(3)];
if Args.Verbose 
    disp('-------------------------');
    disp([fieldname ' ' ccdname ', CCDSEC - [' num2str(CCDSEC) ']'])
    disp([numel(RefTab(:,1)), ' was readed from 9K cat']);
    disp('-------------------------');
end





