function Set = readPipeParameters(SavePath,Args)
arguments
    SavePath;
    Args.SettingFileName = 'master.txt';
end


Set = readtable([SavePath , Args.SettingFileName]);
Set = table2struct(Set);
