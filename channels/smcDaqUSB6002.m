function out = smcDaqUSB6002(ic, val)

% driver for National Instrument DAQ USB-6002
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% channels for this instrument:
% 1-4: Analogue Input (differential) Spectrum (in V/sqrt(Hz))
% 5: Analogue Output (differential)
% 6: Number of averaging
% 7: Number of samples
% 8: df

% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.


global smdata;

format long

s = smdata.inst(ic(1)).data.session;
ID = smdata.inst(ic(1)).data.device.ID;

switch ic(2)
    case {1,2,3,4}  %analogue inputs
        switch ic(3)
            case 0 %get
                navg = smdata.inst(ic(1)).data.navg;
                nsamp = smdata.inst(ic(1)).data.nsamp;
                srate = smdata.inst(ic(1)).data.srate;
                Duration = nsamp/srate;
                s.DurationInSeconds = Duration;
                addAnalogInputChannel(s,ID, ic(2)-1, 'Voltage');
                pavg = [];
                for i=1:navg
                    sig = s.startForeground();
                    sig = sig-mean(sig);                    
                    power=abs(fft(sig)).^2.*2;
                    power=power(1:nsamp/2+1);
                    power=power/(nsamp*srate);                                     
                    if i==1
                        pavg=power;
                    else
                        pavg=pavg+power;
                    end                                
                end
                pavg = pavg/navg;
                out = pavg.^0.5;
                removeChannel(s,1);
        end
        
    case 6  %number of averaging
        switch ic(3)
            case 0 %get
                out = smdata.inst(ic(1)).data.navg;
            case 1 %set
                smdata.inst(ic(1)).data.navg = val;
        end
        
    case 7 %number of samples
        switch ic(3)
            case 0 %get
                out = smdata.inst(ic(1)).data.session.Rate;
            case 1 %set
                smdata.inst(ic(1)).data.nsamp = val;     
        end
        
    case 8 %df
        switch ic(3)
            case 0 %get
                out = smdata.inst(ic(1)).data.srate/smdata.inst(ic(1)).data.nsamp;
            case 1 %set
                smdata.inst(ic(1)).data.nsamp = smdata.inst(ic(1)).data.srate/val;
        end
end







