function se=cull2(data)
% cull2 finds the indices of the data points that are within 2 sigma of the mean
%


% why are some of these lines not commented?
m = median(data(:));
s = median(abs(data(:)-m));
se = find(abs(data(:)-m) < 2*s);
m = mean(data(se));
se = find(abs(data(:)-m) < 2*s);
return

