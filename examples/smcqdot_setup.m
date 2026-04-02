function [inst_idx, chan_start] = smcqdot_setup()
% smcqdot_setup  Register mock quantum dot instrument in smdata.
%
% Appends a new smdata.inst entry for the mock quantum dot and registers
% all 11 channels in smdata.channels via smaddchannel.
%
% Returns:
%   inst_idx  - index of the new instrument in smdata.inst
%   chan_start - index of the first channel added to smdata.channels
%
% Channel layout (offset from chan_start):
%   +0 S    +1 SQ   +2 A1   +3 A2   +4 T1
%   +5 P    +6 T2   +7 Vsd  +8 I    +9 count   +10 I_buf
%
% Example:
%   global smdata;
%   smdata.inst     = struct([]);
%   smdata.channels = struct([]);
%   smdata.datadir  = 'C:/data/my_experiment';
%   [inst_idx, chan_start] = smcqdot_setup();
%   sminitdisp();

global smdata;

V_TH_CENTER = 0.6;
V_TH_SPREAD = 0.1;
N_GATES     = 7;
N_CHAN      = 11;

chanNames = {'S','SQ','A1','A2','T1','P','T2','Vsd','I','count','I_buf'};

inst_n = length(smdata.inst) + 1;

% Seed threshold voltages reproducibly from the instrument index
rng(inst_n, 'twister');

smdata.inst(inst_n).name    = 'QDot';
smdata.inst(inst_n).device  = 'mock_qdot';
smdata.inst(inst_n).cntrlfn = @smcqdot;
smdata.inst(inst_n).channels = char(chanNames);
smdata.inst(inst_n).type=zeros(N_CHAN,1); % 1 for self ramping

smdata.inst(inst_n).data.val       = zeros(N_CHAN, 1);
smdata.inst(inst_n).data.vth       = randn(N_GATES, 1) * V_TH_SPREAD + V_TH_CENTER;
smdata.inst(inst_n).data.ibuf      = [];
smdata.inst(inst_n).data.ibuf_npts = 0;

% datadim: 1 (scalar) for all channels; I_buf updated to npts on configure
smdata.inst(inst_n).datadim = ones(N_CHAN, 1);

inst_idx  = inst_n;
chan_start = length(smdata.channels) + 1;

for i = 1:N_CHAN
    smaddchannel(inst_n, i, chanNames{i});
end

end
