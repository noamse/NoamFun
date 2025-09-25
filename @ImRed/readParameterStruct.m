function Set = readParameterStruct(self,Args)
arguments
    self;
    Args.ParameterFilePath = [];
    Args.SettingFileName = 'master.txt';
    Args.opts = [];
end
fullpath = fullfile(self.SetFilePath, Args.SettingFileName);
%opts = detectImportOptions(fullpath );
if isempty(Args.opts)
    Set = readtable([self.SetFilePath, Args.SettingFileName]);
else
    Set = readtable(fullpath,opts);
end
%disp(Set.Properties.VariableNames)

Set = table2struct(Set);
