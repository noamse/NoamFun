function Col =  generate_col_struct(ColCell,varargin)
% generate the Col struct that relate field name with column index in a matrix 
% index from cells array 



Col =[];
for FieldInd = 1:numel(ColCell)
    Col.(ColCell{FieldInd}) = FieldInd;
end


end