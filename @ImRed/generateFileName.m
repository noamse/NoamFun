function FilePath    = generateFileName(self)

D =dir(self.ImagePath);
D = split(D.name,'.');
FileName = D{1};
FilePath = [self.CatPathTarget,FileName,self.TargetFileExtention];





end