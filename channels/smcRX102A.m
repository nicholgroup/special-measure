function [val] = smcRX102A(ico,val)
%Driver for Lakeshore RX-102A temperature monitor
%Measures resistance using DMM, returns the corresponding temperature
%See: Box/Nichol Group/Docs/Lakeshore for documents
%STM: 02/14/2022
%fprintf('Did you put DMM in 4-point mode?\n')
switch ico(3)
    case 0
        R = cell2mat(smget('DMM2'));
        %R=1204.75: test value for 8K
        val = Temp(R);
    otherwise
        error('Operation not supported.\n')
end
end

function [Output] = Temp(R)
%This function takes the resistance (in Ohms) of the sensor element as the 
% input and calculates the corresponding temperature (in K) using the curve 
% fitting parameters that can be found in
% Nichol Group/Docs/Lakeshore/rx-102a/RX102curve.pdf
    ZLU = [3.35453159798 5.0;3.08086045368 3.44910010859;2.955 3.1085555272]; 
%The parameters from the mentioned document above have been stored in the
%arrays defined here. For each array, the data corresponding to a fit
%range has been stored row-wise. For e.g. the 1st row of ZLU array includes
% the ZL and ZU parameter for the first fit range (0.05 K - 0.95 K). Array 
% A contains the A(0) constants from the document.
    A = [0.300923 -0.401714 0.220055 -0.098891 0.046804 ...
        -0.017379 0.009090 -0.002703 0.002170 0; ...
        2.813252 -2.976371 1.299095 -0.538334 0.220456 ...
        -0.090969 0.037095 -0.015446 0.005104 -0.004254; ...
        3074.395992 -5680.735415 4510.873058 -3070.206226 1775.293345 ...
        -857.606658 336.220971 -101.617491 21.390256 -2.407847];
        z = log10(R);
        summa=0; %Initializing summa
 %The algorithm uses Eqs (1), (2) and (4) from the document to do the 
 %necessary calculation
    if (ZLU(3,1)<z) && (z < ZLU(3,2))
        x = ((z-ZLU(3,1))-(ZLU(3,2)-z))/(ZLU(3,2)-ZLU(3,1));
        for i = 0:9
            summa = summa + A(3,i+1)*cos(i*acos(x));
        end
    elseif (ZLU(2,1)<z) && (z <ZLU(2,2))
        x = ((z-ZLU(2,1))-(ZLU(2,2)-z))/(ZLU(2,2)-ZLU(2,1));
        for i = 0:9
            summa = summa + A(2,i+1)*cos(i*acos(x));
        end
    elseif (ZLU(1,1)<z) && (z <ZLU(1,2))
        x = ((z-ZLU(1,1))-(ZLU(1,2)-z))/(ZLU(1,2)-ZLU(1,1));
        for i = 0:9
            summa = summa + A(1,i+1)*cos(i*acos(x));
        end 
    else
        fprintf('Out of reliability range.\n'); %[0.05K - 40 K]
    end
    Output = summa;%round(summa,3); %Accuracy of deviced limited to 1 mK.
end
