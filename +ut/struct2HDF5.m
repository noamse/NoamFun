function struct2HDF5(inStruct,hdf5Name)
sFields = fieldnames(inStruct);
delete(hdf5Name)
for sf = sFields.'    
    if ~isempty(inStruct.(char(sf)))
        if ~(iscell(inStruct(1).(char(sf))))
            h5create(hdf5Name,['/' char(sf)], size(inStruct.(char(sf))),'Datatype',class(inStruct(1).(char(sf))))
            h5write(hdf5Name,['/' char(sf)],[inStruct.(char(sf))]);
        end
    end
end