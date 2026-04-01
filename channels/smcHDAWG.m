function val = smcHDAWG(ico, val, rate)
% function val = smcHDAWG(ico, val, rate)
% driver for Zurich Instrument HDAWG
% 1: clock, 2-9: CH1-8 amplitude, 10: User register 1 (pulseline)


global smdata;
global awgdata;

%device = smdata.inst(ico(1)).data.device;
device = awgdata.awg.device;

switch ico(2)
    
    case 1 %clock
        switch ico(3)
            case 0 %get
                val = ziDAQ('getDouble',['/' device '/system/clocks/sampleclock/freq']);
            case 1 %set
                ziDAQ('setInt',['/' device '/system/clocks/sampleclock/freq'],1e9);
                ziDAQ('sync');
        end
        
    case {2,3,4,5,6,7,8,9} %output range
        ch = ico(2)-2;
        switch ico(3)
            case 0 %get                
                val = ziDAQ('getDouble', ['/' device '/sigouts/' num2str(ch) '/range']);
            case 1 %set
                if val>5.0
                    warning('Amplitude out of max range (5V), setting to 5V instead.');
                    val = 5.0;
                elseif val<0
                    warning('Negative amplitude, setting to 0V instead');
                end
                ziDAQ('setDouble', ['/' device '/sigouts/' num2str(ch) '/range'], val);
                ziDAQ('sync');
        end
        
    case 10 %pulseline
        switch ico(3)
            case 0 %get   
                val = ziDAQ('getDouble', ['/' device '/awgs/0/userregs/0']);
            case 1 %set
                %first stop sequencer, change userregs, then start sequencer
                ziDAQ('setInt', ['/' device '/awgs/0/enable'], 0);
                ziDAQ('setDouble', ['/' device '/awgs/0/userregs/0'], val);
                ziDAQ('sync');
                ziDAQ('setInt', ['/' device '/awgs/0/enable'], 1);
                ziDAQ('sync');
        end
        
        
    otherwise
        1;

end
