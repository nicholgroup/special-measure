function val = smc3310A(ic, val, rate)
% 1: freq, 2: amplitude, 3: offset


global smdata;

%cmds = {':FREQ:CW %.10f MHz; *LCL;', ':AMPL:CW %f dBm'};
%cmds = {':FREQ %.10f Hz', ':VOLT %.6f',':VOLT:OFFS %.6f'};
cmds = {':FREQ %.10f Hz', ':VOLT %.3f',':VOLT:OFFS %.3f'}; %modified 6/6/2023 xxc
queries={':FREQ?',':VOLT?',':VOLT:OFFS?'};
scales = [1, 1, 1];
switch ic(3)
    case 1
        fprintf(smdata.inst(ic(1)).data.inst, sprintf(cmds{ic(2)},val/scales(ic(2))));
    case 0
        val = query(smdata.inst(ic(1)).data.inst, queries{ic(2)}, '%s\n', '%f');
    otherwise
        error('Operation not supported');
end