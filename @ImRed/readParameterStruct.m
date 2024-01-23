function Set = readParameterStruct(self,Args)
arguments
    self;
    Args.ParameterFilePath = [];
    Args.SettingFileName = 'master.txt';
end


Set = readtable([self.SetFilePath, Args.SettingFileName]);
Set = table2struct(Set);
