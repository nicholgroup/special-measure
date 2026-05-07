function [out] = diffsens(file)
%diffsens(file) outputs and plots the scan and the absolute value of the derivative of the data. 
% Only takes 1D scans at present.

if ~exist('file','var') || isempty(file)
    file = smgetfile;
end

d = load(file);

if iscell(d.scan.loops(1).setchan)
    xlab = d.scan.loops(1).setchan{1};
else
    xlab = d.scan.loops(1).setchan;
end

x = linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
y = d.data{1};
dx = gradient(x);
dy = gradient(y);
sens = abs(dy./dx);
[maxsens,ind] = max(sens);

out.x = x;
out.y = y;
out.dx = dx;
out.dy = dy;
out.sens = sens;
out.maxsens = maxsens;
out.maxsens_x = x(ind);

figure(987); clf; 
subplot(1,2,1);
plot(x,y,'b'); hold on;
plot(x(ind),y(ind),'kx','MarkerSize',10);
xlabel(xlab);
ylabel(d.scan.loops(2).getchan); 
xlim([min(x) max(x)]);

subplot(1,2,2);
plot(x,sens,'r'); hold on;
plot(x(ind),sens(ind),'kx','MarkerSize',10);
xlabel(d.scan.loops(1).setchan);
ylabel('differential sensitivity'); 
xlim([min(x) max(x)]);

opts=struct();
opts.file=file;
opts.body = sprintf('max sens=%0.1f at %s=%0.4f',maxsens,xlab,x(ind));
opts.title='diffsens output';
opts.figures=[987];
pptprep(opts);

