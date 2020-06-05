function outStruct = HDF52struct(hdf5Name)
fInfo = h5info(hdf5Name);
sFields ={fInfo.Datasets.Name};
sSize   = max(fInfo.Datasets(1).Dataspace.Size);
outStruct(sSize).(sFields{1}) = []; %Create struct array with the right number of elements
for sf = sFields 
    tempData = num2cell(h5read(hdf5Name,['/' char(sf)]));
    [outStruct.(char(sf))] = deal(tempData{:});
end