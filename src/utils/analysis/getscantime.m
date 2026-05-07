function [ scantime ] = getscantime( scan, data )
% getscantime finds the time of the scan.
%
% [ scantime ] = getscantime( scan, data ) takes a loaded scan and data,
% try to guess a time to use for plsinfo
%check to see how time is documented.  changed 2/17/2011

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.

if strcmp(func2str(scan.loops(1).procfn(1).fn(end).fn), 'smpSnglShot');
    timechan=length(data);  % Histogram code moves time channel around.
else
    
    timechan=strmatch('Time',scan.loops(1).getchan);
end

if(isempty(timechan))
    scantime=[];
else
    scantime=data{timechan}(1);
end
end

