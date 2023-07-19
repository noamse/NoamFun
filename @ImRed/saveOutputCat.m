function saveOutputCat(self,Cat)

FilePath    = generateFileName(self);
save(FilePath,'Cat');