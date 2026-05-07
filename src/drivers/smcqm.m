function [val, rate] = smcqm(ico, val, rate)
% driver for quantum machines hardware
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% Channels for the instrument:
% 1: data from experiment
% 2: histogram
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure

global smdata;

file=smdata.inst(ico(1)).data.file;

switch ico(2) %
    case 1 %data
        switch ico(3)
            case 0 %get
                [val,counts]=pyrunfile(file,["data","counts"],state=1);
                val=double(val);
                val=val(:);
                smdata.inst(ico(1)).data.counts=double(counts);
            case 5 %configure
                val=double(pyrunfile(file,"data",state=0));
            otherwise
                error('Operation not supported');
        end
    case 2 %histogram
        switch ico(3)
            case 0 %get
                val=smdata.inst(ico(1)).data.counts;
            otherwise
                error('Operation not supported');
        end


end

end