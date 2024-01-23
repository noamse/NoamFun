classdef ImRed
    
    
    properties
        ImagePath           = [];
        SetFilePath         = [];
        Cat                 = [];
        JD                  = [];
        Set                 = [];
        CatPathTarget       = [];
        RefCatalogFilePath  = [];
        RefCatalog          = [];
        TargetFileExtention = '_AstCat.mat';
        
    end
    

        methods(Static)
            p = testFun(tol)
            [Cat] = runPipe(ImagePath,CatPathTarget)
            Set         = setParameterStruct(CatPathTarget);
        end
   

    
    
    
    methods
        
        Im          = loadImage(self); % done
        RefCat      = loadRefCat(self,Args)
        Im          = constructPSF(self,Im); % Need to add the selectPsfStars parameters to Set
        Im          = populatePSFKernel(self,Im); % done
        Cat         = iterativePSFPhot(self,Im); % tbd
        RefCat      = adjustRefCat(self,Im); % tbd
        Set         = readParameterStruct(self,Args);
        FilePath    = generateFileName(self);
        Cat         = populateMetaData(self,Cat,Im);
                      saveOutputCat(self,Cat);
    end
    
    methods
        
        function self = ImRed(ImagePath,CatPathTarget,Args)
            arguments
                ImagePath;
                CatPathTarget;
                Args.SetFilePath = [];
                Args.RefCatPath  = [];
            end
            self.CatPathTarget  = CatPathTarget;
            self.ImagePath = ImagePath;
            if (isempty(Args.SetFilePath ))
                self.SetFilePath = CatPathTarget;
            else
                self.SetFilePath = Args.SetFilePath ;
                
            end
            if isempty(Args.RefCatPath)
                self.RefCatalogFilePath = CatPathTarget;
            else
                self.RefCatalogFilePath = Args.RefCatPath;
            end
            
        end
        
        function makeTargetDir(self)
            mkdir(self.CatPathTarget);
            
        end
        
        
        
        
        function self=mainRun(self)
            
            
            self.Set  = setParameterStruct(self);
            Im      = loadImage(self); % done
            Im      = constructPSF(self,Im); % Need to add the selectPsfStars parameters to Set
            Im      = populatePSFKernel(self,Im); % done
            self.RefCatalog  = adjustRefCat(self,Im); % tbd
            self.Cat    = iterativePSFPhot(self,Im);
        end
        %         function Set = readPipeParameters(self,Args)
        %             arguments
        %                 self;
        %                 Args.SettingFileName = 'master.txt';
        %             end
        %
        %
        %             Set = readtable([self.SetFilePath , Args.SettingFileName]);
        %             Set = table2struct(Set);
        %
        %         end
        
        
        
        
        function RefCatalog  = readRefCatlaog(self,Args)
            arguments
                self;
                Args.SavedCatFileName = 'ogle_cat.mat';
                Args.CatFieldName = 'ogle_cat';
                %Args.CatFieldName = 'RefCatalog';
                
                
            end
            
            TempFileStruct= load([self.RefCatalogFilePath Args.SavedCatFileName]);
            RefCatalog=TempFileStruct.(Args.CatFieldName);
            
            
        end
        
        
        
    end
    
end
