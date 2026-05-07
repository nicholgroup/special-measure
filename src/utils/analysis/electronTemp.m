function [ Tel ] = electronTemp(Tel0,p,Tmc)
%[ Tel ] = electronTemp(Tel0,p,Tmc) computes the electron temperature
% Tel0: electron temperature at Tmc=0
% p: exponent describing how thermal conductivity depends on temperature
% Tmc: mixing chamber temperature


Tel=[];

for z=1:length(Tmc) 
    Tel(z)=fzero(@(x) x-Tel0^(p+1)./(x.^p)-Tmc(z),Tel0+Tmc(z));
end

end

