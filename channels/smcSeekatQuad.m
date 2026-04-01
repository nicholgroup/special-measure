function [val, rate] = smcSeekatQuad(ico, val, rate)
%
%Channels on the DAC are labelled 0-3
%Operational Codes
%0: Get
%1: Set or Ramp
global smdata;

switch ico(2)
    case 1 %Channel 0
        switch ico(3)
            case 0 %get 
                val=query(smdata.inst(ico(1)).data.inst,'GET_DAC,0'); 
                val=str2double(val);
            case 1 %set
                if exist('rate','var') && isfinite(rate)
                    k=query(smdata.inst(ico(1)).data.inst,'GET_DAC,0');
                    kd = str2double(k);
                    steps = round(abs((val-kd)*100));
                    delay = (1/rate)*1000; %milliseconds
                    query(smdata.inst(ico(1)).data.inst,['RAMP1,0,' num2str(kd) ',' num2str(val) ',' num2str(steps) ',' num2str(delay)]);
                else
                    query(smdata.inst(ico(1)).data.inst,['SET,0,' num2str(val)]);    
                end
            otherwise
                error('Operation not supported');
        end
    case 2 %Channel 1
        switch ico(3)
            case 0 %get 
                val=query(smdata.inst(ico(1)).data.inst,'GET_DAC,1'); 
                val=str2double(val);
            case 1 %set
                if exist('rate','var') && isfinite(rate)
                    k=query(smdata.inst(ico(1)).data.inst,'GET_DAC,1');
                    kd = str2double(k);
                    steps = round(abs((val-kd)*100));
                    delay = (1/rate)*1000; %milliseconds
                    query(smdata.inst(ico(1)).data.inst,['RAMP1,1,' num2str(kd) ',' num2str(val) ',' num2str(steps) ',' num2str(delay)])
                else
                    query(smdata.inst(ico(1)).data.inst,['SET,1,' num2str(val)]);          
                end
            otherwise
                error('Operation not supported');
        end
    case 3 %Channel 2
        switch ico(3)
            case 0 %get 
                val=query(smdata.inst(ico(1)).data.inst,'GET_DAC,2'); 
                val=str2double(val);
            case 1 %set
                if exist('rate','var') && isfinite(rate)
                    k=query(smdata.inst(ico(1)).data.inst,'GET_DAC,2');
                    kd = str2double(k);
                    steps = round(abs((val-kd)*100));
                    delay = (1/rate)*1000; %milliseconds
                    query(smdata.inst(ico(1)).data.inst,['RAMP1,2,' num2str(kd) ',' num2str(val) ',' num2str(steps) ',' num2str(delay)])
                else
                    query(smdata.inst(ico(1)).data.inst,['SET,2,' num2str(val)]);          
                end
            otherwise
                error('Operation not supported');
        end
    case 4 %Channel 3
        switch ico(3)
            case 0 %get 
                val=query(smdata.inst(ico(1)).data.inst,'GET_DAC,3'); 
                val=str2double(val);
            case 1 %set
                if exist('rate','var') && isfinite(rate)
                    k=query(smdata.inst(ico(1)).data.inst,'GET_DAC,3');
                    kd = str2double(k);
                    steps = round(abs((val-kd)*100));
                    delay = (1/rate)*1000; %milliseconds
                    query(smdata.inst(ico(1)).data.inst,['RAMP1,3,' num2str(kd) ',' num2str(val) ',' num2str(steps) ',' num2str(delay)])
                else
                    query(smdata.inst(ico(1)).data.inst,['SET,3,' num2str(val)]);          
                end
            otherwise
                error('Operation not supported');
        end
end