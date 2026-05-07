function [ ] = scanPulse(file, grpInd, plsInd)
%scanPulse recreates and plots the pulse from a specific data file
%
% This function calls atplschk, so you need to have set up plsdata on your
% computer first.
%
% Variables added 11/7/2022 XXC
%   grpInd: specify the group number, otherwise plot the middle group
%   plsInd: specify the pulse number, otherwise plot the middle pulse
%
% Fixes 8/26/24: JMN
%   Added in-function plsdata and awgdata setup. 
%

global plsdata
global awgdata
global tunedata


if isempty(plsdata)
    fprintf('Please load plsdata.\n');
    [filename pathname]=uigetfile('plsdata*');
    load(fullfile(pathname,filename));
    
    curdir=pwd;
    bp=curdir(1:regexp(curdir,'\\Nichol Group'));
    plsdata.grpdir=[bp plsdata.grpdir(regexp(plsdata.grpdir,'\Nichol Group'):end)];
    plsdata.datafile=[bp plsdata.datafile(regexp(plsdata.datafile,'\Nichol Group'):end)];
    
end

if isempty(awgdata)
    fprintf('Please load awgdata.\n');
    [filename pathname]=uigetfile('awgdata*');
    d=load(fullfile(pathname,filename));
    awgdata=d.data;
end

if isempty(tunedata)
    fprintf('Please load tunedata.\n');
    [filename pathname]=uigetfile('tunedata*');
    load(fullfile(pathname,filename));
end

if ~exist('file','var') || isempty(file)
    [filename pathname]=uigetfile('sm_*.mat');
    file={fullfile(pathname,filename)};
end

d=load(file{1});
scanTime=getscantime(d.scan,d.data);

names={d.scan.data.pulsegroups.name};
fprintf('%d pulses in groups\n',d.scan.data.pulsegroups(1).npulse(1));

if ~exist('grpInd','var') || isempty(grpInd)
    grpInd = round(length(names)/2);
end
if ~exist('plsInd','var') || isempty(plsInd)
    plsInd = d.scan.data.pulsegroups(1).npulse(1)/2;
end

config=struct();
config.time=scanTime;
config.pulses=plsInd;
%config.pulses=d.scan.data.pulsegroups(1).npulse(1)/2;

figure(55); clf; atplschk(names{grpInd},config);
%figure(55); clf; atplschk(names{round(length(names)/2)},config);

end

function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
return;
end
