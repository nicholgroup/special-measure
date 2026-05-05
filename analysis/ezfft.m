function [y,freq]=ezfft(data,dt,dim,zpN)
%ezfft returns the two-sided fft of data.
%
%[y,freq] = ezfft(data,dt,dim,zpN) returns the two-sided fft (y), assuming the data start from t = 0, freq is the
%frequency with length floor(L/2), where L is the total time step
%  dt: time step, defult is 1
%  dim: operates along dimension dim, default is the first non-singleton
%  dimension
%  zpN: number of points for zero padding, appended along the dimension
%  specified by dim


if ~exist('dt','var')
    dt=1;
end

if ~exist('dim','var') || isempty(dim)
    dim = find(size(data)~=1,1);
end

if exist('zpN','var')&&zpN>0
    dsize=size(data);
    dsize(dim)=zpN;
    zTable=zeros(dsize);
    data=cat(dim,data,zTable);
end

dsize=size(data);
L=dsize(dim);

t=(0:L-1).*dt;
freq=1/L*(0:(L/2-1))./dt;

y=abs(fft(data,[],dim));

%ADD ME: how to make it return one-sided fft for arbitrary dim?

end