function astcat = clear_failure(astcat)
% Clear the astcat that contain catalog which astrometry failed to solve.
Flag = true(size(astcat));
for i=1:numel(astcat)
    try numel(fields(astcat(i).UserData.R));
        if (numel(fields(astcat(i).UserData.R))<=2)
            Flag(i)=false;
        end
    catch ME;
        Flag(i)=false;
    end
end

astcat = astcat(Flag);




end