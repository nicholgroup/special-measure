function [ y ] = antiSymPeak(p,x)
%antiSymPeak is for use with fitwrap to fit asymmetric peaks.

fn=@(p,x) p(2)*exp(-(abs(x-p(3))/p(4))^p(5)); 
fnR=@(p,x) p(1)+p(2)*exp(-(abs(x-p(3))/p(6))^p(7)); 

y=zeros(1,length(x));

for i=1:length(x)
    if x(i)<p(3)
        y(i)=fnL(p,x(i));
    else 
        y(i)=fnR(p,x(i));
    end
end
    
    
end

