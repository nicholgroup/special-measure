function val = smcLabBrick_v2(ico, val, rate)
%function val = smcLabBrick(ic, val, rate)
% Control function for LabBricks from Vaunix.
% Only minimal functionality is supported.
% 1: freq, 
% 2: power, 
% 3: rf on/off
% 4: intitialize
% 12: print sn

% example: instrument 20 is a lab brick:
%  smcLabBrick([20 3 1],1) will turn on power

persistent holdoff; % Used to guarantee small pause between open and close
if ~exist('holdoff','var')
    holdoff=0;
end

global smdata;

% Open the library if needed.
if ~libisloaded('vaunixapi')
  p=strrep(which('smcLabBrick'),'smcLabBrick.m','labbrick') ;    
  addpath(p);
  if ~lbLoadLibrary_v2
      error('Unable to load vaunixapi');
  end
  rmpath(p);
  smdata.inst(ico(1)).data.devhandle=[];
end

%the following will break with more than one labbrick. 

calllib('vaunixapi','fnLSG_SetTestMode',0);
nlb=calllib('vaunixapi','fnLSG_GetNumDevices');

%make sure we've got the right labbrick.
match = 0;
for i=1:nlb
    %lb=calllib('vaunixapi','fnLSG_GetDevInfo',i);
    lb=i; %QHF 2019/01/27: calllib somehow only returns the total number of LabBrick
    if calllib('vaunixapi','fnLSG_GetSerialNumber',lb)==smdata.inst(ico(1)).data.serial
        match = 1;
        break
    end
end

if ~match
    error('cannot identify labbrick');
end

%minimum frequency and power increment
df=100e3;
dP=0.25;

switch ico(2)
    case 1 %freq
        switch ico(3)
            case 1 %set
                f=val;
                calllib('vaunixapi','fnLSG_SetFrequency',lb,f/df);
            case 0 %get
                f=calllib('vaunixapi','fnLSG_GetFrequency',lb);
                val=round(df*f);
        end
        
    case 2 %power
        switch ico(3)
            case 1 %set
                P=val;
                calllib('vaunixapi','fnLSG_SetPowerLevel',lb,P/dP);
            case 0 %get
                P=calllib('vaunixapi','fnLSG_GetPowerLevel',lb);
                val=dP*P;
        end
        
    case 3 %rf on or off
        switch ico(3)
            case 1 %set
                calllib('vaunixapi','fnLSG_SetRFOn',lb,val)
            case 0 %get
                error('Operation not supported')
        end

        
    case 4
        calllib('vaunixapi','fnLSG_InitDevice',lb)
        
    case 12
        for i=1:nlb
            %lb=calllib('vaunixapi','fnLSG_GetDevInfo',i);
            calllib('vaunixapi','fnLSG_GetSerialNumber',i)
        end
        
    otherwise
        error('Operation not supported.');
        
end

end



