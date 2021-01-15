function matrix2latex(FileName,matrix)
%file = 'demo.dat'; % file name
%A = reshape(1:9, 3, 3); % matrix to be written to the file
precision = '%.5f'; % desired precision for values in A (for possible values of this parameter, see https://www.mathworks.com/help/matlab/ref/fprintf.html#btf8xsy-1_sep_shared-formatSpec)
delimiter = ' & ';
line_terminator = ' \\ \n ';
write_general_matrix(FileName, matrix, precision, delimiter, line_terminator);

end
function write_general_matrix(FileName, matrix, precision, delimiter, line_terminator)
format = [create_fmt(precision, delimiter, size(matrix, 2)) line_terminator];
fid = fopen(FileName, 'w');
fprintf(fid, format, matrix');
fclose(fid);
end
function s = create_fmt(prec, dlm, n_fmt)
s = prec;
for i = 1:2*(n_fmt-1)
    if mod(i, 2) == 1
        s = [s dlm];
    else
        s = [s prec];
    end
end
end