%Author: David Peles
function im = bImread(fname,rows,cols,dtype,offset)
fd = fopen(fname,'rb');
data = fread(fd,dtype);
if exist('offset','var')
    data = data(offset+1:end);
end
im = reshape(data,cols,rows)';
fclose(fd);