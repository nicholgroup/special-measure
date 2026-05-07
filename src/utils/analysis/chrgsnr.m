function [out] = chrgsnr(x,y,z)
% chrgsnr(x,y,z) estimates snr of a charge scan. A little rough. 
%To be used within plotchrg.m

xmat = (x'*ones(1,length(y)))';
ymat = y'*ones(1,length(x));

% define regions with noise, charge transition x, and charge transition y
display('Please choose 4 points defining region where there is NO charge transitions.');
[xn,yn]= ginput(4);
display('Please choose 4 points defining region where there is a charge transition that intersects the x axis');
[xx,yx]= ginput(4);
display('Please choose 4 points defining region where there is a charge transition that intersects the y axis');
[xy,yy]= ginput(4);

pn = polyshape(xn,yn); %polygon defining noise region
px = polyshape(xx,yx); %polygon defining charge transition that intersects x axis
py = polyshape(xy,yy); %polygon defining charge transition that intersects y axis

hold on;
plot(pn,'FaceColor','red','FaceAlpha',0.1,'DisplayName','Noise Region');
plot(px,'FaceColor','blue','FaceAlpha',0.1,'DisplayName','X Signal Region');
plot(py,'FaceColor','green','FaceAlpha',0.1,'DisplayName','Y Signal Region');
legend('Location','northeast');

inn = inpolygon(xmat,ymat,xn,yn); %logical array corresponding to if points are in noise polygon
inx = inpolygon(xmat,ymat,xx,yx); %logical array corresponding to if points are in x polygon
iny = inpolygon(xmat,ymat,xy,yy); %logical array corresponding to if points are in y polygon

sigx = [];
for i=1:length(y)
	temp = z(i,inx(i,:));
    if any(temp)
        sigx = [sigx max(abs(temp))];
    end
end
sigy = [];
for i=1:length(x)
	temp = z(iny(:,i),i);
    if any(temp)
        sigy = [sigy max(abs(temp))];
    end
end

% remove outlier points corresponding to columns/rows that do not have
% charge transitions in them. added 2021/12/22
sigx = sigx(sigx > (mean(sigx)-2*std(sigx))); %hahahahha
sigy = sigy(sigy > (mean(sigy)-2*std(sigy))); %hahahahha


noise = std(z(inn));
avgx = mean(sigx);
stdx = std(sigx);
snrx = avgx/noise;
avgy = mean(sigy);
stdy = std(sigy);  
snry = avgy/noise;

%QHF 2021/12/28: changed to 3 decimal point precision, since the noise is nomrlly around O(0.01)   
outstr = sprintf('Noise=%0.3f\nX signal=%0.3f +- %0.3f (SNR=%0.3f)\nY signal=%0.3f +- %0.3f (SNR=%0.3f)',noise*1e3,avgx*1e3,stdx*1e3,snrx,avgy*1e3,stdy*1e3,snry);

out = struct;
out.noise = noise;
out.sigx = avgx;
out.sigy = avgy;
out.snrx = snrx;
out.snry = snry;
out.outstr = outstr;


end

