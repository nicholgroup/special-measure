function [] = smcZIMFIAInit(device_id,inst)
% smcZIMFIAInit initializes the ZI MFIA

global smdata;

clear ziDAQ;

% Check the ziDAQ MEX (DLL) and Utility functions can be found in Matlab's path.
if ~(exist('ziDAQ') == 3) && ~(exist('ziCreateAPISession', 'file') == 2)
    fprintf('Failed to either find the ziDAQ mex file or ziDevices() utility.\n')
    fprintf('Please configure your path using the ziDAQ function ziAddPath().\n')
    fprintf('This can be found in the API subfolder of your LabOne installation.\n');
    fprintf('On Windows this is typically:\n');
    fprintf('C:\\Program Files\\Zurich Instruments\\LabOne\\API\\MATLAB2012\\\n');
    return
end

apilevel = 6;
% Create an API session; connect to the correct Data Server for the device.
[device, props] = ziCreateAPISession(device_id, apilevel);
ziApiServerVersionCheck();

smdata.inst(inst).data.inst=device; %not sure if this is the correct places for this. 
end
        
