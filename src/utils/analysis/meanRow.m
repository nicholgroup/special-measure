function [mdata] = meanRow(data)
%meanRow takes a 2D matrix data and fixes the mean of each row to be equal to the mean of the whole dataset

%m1 = nanmean(data(1,:));
m1 = nanmean(nanmean(data,2));
mdata = zeros(size(data));
for i=1:size(data,1)
    row = data(i,:);
    mi = nanmean(row);
    dm = m1-mi;
    mdata(i,:) = row+dm;
end


end

