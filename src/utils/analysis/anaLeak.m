function [  ] = anaLeak(file,config)
%anaLeak analyzes leakage current through a gate.
%
% See Tester/Scripts/DotTestScans_2019_12_19 for an example of a scan. 
% The The gate voltage should be applied through a resistor
% (scan.data.resistance), and the voltage accross the resistance should be
% measured with a DMM. The data from the DMM in should be the first getchan
% in scan.loops(1).

if ~exist('file','var')|| isempty(file)
    file=uigetfile('sm*.mat','MultiSelect','on');
end

if ~iscell(file)
    file={file}
end

if ~exist('config','var')
    config=struct();
end

config = def(config,'opts','');   % Random boolean options

d=load(file{1});


try
    resistance=d.scan.data.resistance;
catch
    %warning('no resistance given. assuming 100 M ohms');
    resistance=input('Input the resistance \n');
end


dV=(d.scan.loops(1).rng(2)-d.scan.loops(1).rng(1))/d.scan.loops(1).npoints;
dt=d.scan.loops(1).ramptime;
vdot=dV/dt;
xv=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);

yv=d.data{1}';

figure(222);clf; 

if length(d.data)~=1
    nplots=2;
else
    nplots=3;
end
nplots=length(d.data)+1

subplot(nplots,1,1);
current=(xv-yv)./resistance;
plot(xv,current)
xlabel('Gate Voltage'); ylabel('Leakage current');

if isopt(config,'cv')
    cap=current/vdot;
    subplot(nplots,1,2);
    plot(xv,cap);
    xlabel('Gate Voltage'); ylabel('Capacitance');
else
    subplot(nplots,1,2);
    indx=find(strcmpi(d.scan.loops(1).getchan, 'DMM')); % HY: 08/12/25, some people put DMM and lockin in different orders. so better to find it.
    plot(xv,d.data{indx});
    xlabel('Gate Voltage'); ylabel('Actual gate voltage');
end


if length(d.data)~=1 % HY:08/04/23 added to avoid error when plotting for leakage scans only.
    subplot(nplots,1,3);
    indx=find(strcmpi(d.scan.loops(1).getchan, 'lockin')); % HY: 08/12/25
    plot(xv,d.data{indx});
    xlabel('Gate Voltage'); ylabel('Current');
end

sgtitle(sprintf('Leakage with dV/dt=%f V/s',vdot));

opts=struct();
opts.file=file{1};
opts.title=file{1};
opts.figures=222;
pptprep(opts);


return;



function b=isopt(config,name)
b=~isempty(strfind(config.opts,name));
return;


function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;


