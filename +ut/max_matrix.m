function [row,column,value] = max_matrix(A)
[y,in] = max(A);
[value,column] = max(y);
[~,row] = max(A(:,column));
end