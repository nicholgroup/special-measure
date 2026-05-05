function [Pxx,F] = ezpsd(T,D)
%EZPSD computes the single-sided power spectrum of a time-series
%[Pxx,F] = ezpsd(T,D)
%This is a wrappter for the periodogram function.
%   T is either a list of times or the time interval between points in the
%   time series
%   D is the time series
%   Pxx is the power spectrum
%   F is a list of frequencies
if length(T)==1
    dT=T;
else
    dT=T(2)-T(1);
end
[Pxx,F]=periodogram(D,[],length(D),1/dT,'onesided');
end

