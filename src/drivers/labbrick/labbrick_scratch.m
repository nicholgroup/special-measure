 p=strrep(which('smcLabBrick'),'smcLabBrick.m','labbrick\vaunix\') ;
 
addpath(p)

libname='vnx_fsynth';
hname='vnx_LSG_api';

[notfound,warnings]=loadlibrary([p libname '.dll'],[p hname '.h'],'alias','vaunixapi');
notfound
warnings

rmpath(p);

%unloadlibrary('vaunixapi');

%%
calllib('vaunixapi','fnLSG_SetTestMode',0)

calllib('vaunixapi','fnLSG_GetNumDevices')

lb=calllib('vaunixapi','fnLSG_GetDevInfo',0)

for i = 1:lb
    
    calllib('vaunixapi','fnLSG_InitDevice',i)
    calllib('vaunixapi','fnLSG_GetSerialNumber',i)
    
    df=100e3;
    f=215e6;
    calllib('vaunixapi','fnLSG_SetFrequency',i,f/df);
    calllib('vaunixapi','fnLSG_GetFrequency',i)
    
    dP=.25;
    P=10;
    calllib('vaunixapi','fnLSG_SetPowerLevel',i,P/dP);
    calllib('vaunixapi','fnLSG_GetPowerLevel',i)
    
    calllib('vaunixapi','fnLSG_SetRFOn',i,1)
    
end








