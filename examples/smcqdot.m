function [val, rate] = smcqdot(ico, val, rate)
% smcqdot  Mock quantum dot device driver.
%
% Models a quantum dot as a resistor network:
%
%   Vsd ---[R_A1]---+---[R_parallel]---+---[R_A2]--- GND
%
% where R_parallel = R_S || R_SQ || (R_T1 + R_P + R_T2)
%
% Each gate-controlled resistance transitions from R_MAX (~1 GOhm, off) to
% R_MIN (~10 kOhm, on) via a sigmoid centered at the gate threshold voltage.
% T-gate thresholds are shifted by 10% of the screening gate overdrive
% (cross-talk from S and SQ).
%
% Channels (ico(2), 1-indexed):
%   1  S     gate voltage (screening)
%   2  SQ    gate voltage (screening)
%   3  A1    gate voltage (series accumulation)
%   4  A2    gate voltage (series accumulation)
%   5  T1    gate voltage (tunnel barrier 1)
%   6  P     gate voltage (plunger)
%   7  T2    gate voltage (tunnel barrier 2)
%   8  Vsd   source-drain bias (V)
%   9  I     current through device (A, read-only)
%  10  count dummy counter variable
%  11  I_buf buffered current (A, read-only array)
%            Fills one sample per op=3 trigger; returns array on op=0;
%            resets on op=4 arm.  Use with smabufconfig2.
%
% Operation codes (ico(3)):
%   0  GET       read channel value
%   1  SET       write gate / bias voltage
%   3  TRIGGER   append one I sample to I_buf (no-op on other channels)
%   4  ARM       clear I_buf buffer (no-op on other channels)
%   5  CONFIGURE set buffer size; val=npts, rate=rate; updates datadim
%
% Usage:
%   smcqdot_setup();        % registers instrument and channels in smdata
%   smset('Vsd', 1e-3);
%   smset('S', 0.8);
%   smget('I');

global smdata;

% Physical model constants
R_MIN       = 10e3;   % fully-open resistance  (Ohm)
R_MAX       = 1e9;    % fully-closed resistance (Ohm)
K           = 115.0;  % sigmoid steepness (1/V): ~5 decades over 0.1 V
V_TH_CENTER = 0.6;    % threshold voltage center (V)
V_TH_SPREAD = 0.1;    % threshold voltage std dev (V)
N_GATES     = 7;
N_CHAN      = 11;
I_IDX       = 9;
I_BUF_IDX   = 11;

inst_n = ico(1);
chan   = ico(2);
op     = ico(3);

% --- Lazy initialization on first call ---
if ~isfield(smdata.inst(inst_n).data, 'vth') || isempty(smdata.inst(inst_n).data.vth)
    rng(inst_n, 'twister');
    smdata.inst(inst_n).data.vth = randn(N_GATES, 1) * V_TH_SPREAD + V_TH_CENTER;
end
if ~isfield(smdata.inst(inst_n).data, 'val') || isempty(smdata.inst(inst_n).data.val)
    smdata.inst(inst_n).data.val = zeros(N_CHAN, 1);
end
if ~isfield(smdata.inst(inst_n).data, 'ibuf')
    smdata.inst(inst_n).data.ibuf      = [];
    smdata.inst(inst_n).data.ibuf_npts = 0;
end

switch op
    case 0  % GET
        if chan == I_IDX
            val = computeCurrent(smdata.inst(inst_n).data.val, ...
                                 smdata.inst(inst_n).data.vth, K, R_MIN, R_MAX);
        elseif chan == I_BUF_IDX
            buf  = smdata.inst(inst_n).data.ibuf;
            npts = smdata.inst(inst_n).data.ibuf_npts;
            if isempty(buf)
                val = zeros(max(npts, 1), 1);
            else
                %val = buf(end-npts+1:end); %not sure why this is needed here.
                %val=buf(1:2:end);
                val=buf;
            end
        else
            val = smdata.inst(inst_n).data.val(chan);
        end


    case 1  % SET
        if chan == I_IDX || chan == I_BUF_IDX
            error('smcqdot: channel %d is read-only', chan);
        end
        smdata.inst(inst_n).data.val(chan) = val;
        I_now = computeCurrent(smdata.inst(inst_n).data.val, ...
                                   smdata.inst(inst_n).data.vth, K, R_MIN, R_MAX);
        smdata.inst(inst_n).data.ibuf(end+1) = I_now;

    case 3  % TRIGGER — append one I sample to ibuf (no-op on other channels)
        smdata.inst(inst_n).data.ibuf = [];
        if chan == I_BUF_IDX
            I_now = computeCurrent(smdata.inst(inst_n).data.val, ...
                                   smdata.inst(inst_n).data.vth, K, R_MIN, R_MAX);
            smdata.inst(inst_n).data.ibuf(end+1) = I_now;
        end

    case 4  % ARM — clear ibuf for new outer-loop point (no-op on other channels)
        if chan == I_BUF_IDX
            smdata.inst(inst_n).data.ibuf = [];
        end

    case 5  % CONFIGURE — set buffer size and update datadim
        if chan == I_BUF_IDX
            if isempty(val)
                npts = 1;
            else
                npts = round(val);
            end
            if nargin < 3 || isempty(rate)
                rate = 1e3;
            end
            smdata.inst(inst_n).data.ibuf_npts = npts;
            smdata.inst(inst_n).data.ibuf      = [];
            smdata.inst(inst_n).datadim(I_BUF_IDX) = npts;
            val = npts;
        end

    otherwise
        error('smcqdot: unsupported operation %d', op);
end

end

% -------------------------------------------------------------------------
function I = computeCurrent(vals, vth, K, R_MIN, R_MAX)
% Compute source-drain current for the resistor-network quantum dot model.
% Circuit: R_A1 + (R_S || R_SQ || (R_T1 + R_P + R_T2)) + R_A2

S   = vals(1);  SQ  = vals(2);
A1  = vals(3);  A2  = vals(4);
T1  = vals(5);  P   = vals(6);  T2  = vals(7);
Vsd = vals(8);

vth_S  = vth(1);  vth_SQ = vth(2);
vth_A1 = vth(3);  vth_A2 = vth(4);
vth_T1 = vth(5);  vth_P  = vth(6);  vth_T2 = vth(7);

% Cross-talk: T-gate effective voltage shifted by screening gate overdrive
xt = 0.1*(S - vth_S) + 0.1*(SQ - vth_SQ);

R_S   = resistance(S,       vth_S,  K, R_MIN, R_MAX);
R_SQ  = resistance(SQ,      vth_SQ, K, R_MIN, R_MAX);
R_A1  = resistance(A1,      vth_A1, K, R_MIN, R_MAX);
R_A2  = resistance(A2,      vth_A2, K, R_MIN, R_MAX);
R_T1  = resistance(T1 + xt, vth_T1, K, R_MIN, R_MAX);
R_P_r = resistance(P  + xt, vth_P,  K, R_MIN, R_MAX);
R_T2  = resistance(T2 + xt, vth_T2, K, R_MIN, R_MAX);

R_TPT   = R_T1 + R_P_r + R_T2;
R_par   = 1.0 / (1.0/R_S + 1.0/R_SQ + 1.0/R_TPT);
R_total = R_A1 + R_par + R_A2;
I       = Vsd / R_total;

end

% -------------------------------------------------------------------------
function R = resistance(v, vth, K, R_MIN, R_MAX)
% Sigmoid gate-controlled resistance.
% R = R_MAX when v << vth (gate off), R = R_MIN when v >> vth (gate on).
R = R_MIN + (R_MAX - R_MIN) / (1.0 + exp(K * (v - vth)));
end
