function smset(channels, vals, ramprate)
% function smset(channels, vals, ramprate)
%
% Set channels to vals.
% Channels can be a cell or char array with channel names, or a vector
% with channel numbers.
% vals is a vector with one element for each channel.
% ramprate is used instead of the instrument default if given and finite.
% Its magnitude is clamped to the channel maximum in rangeramp(:,3).
%
% NEGATIVE RAMPRATE
% The sign is a flag, not a direction. The magnitude is the rate actually
% used; the negative sign means smset does not wait for the ramp to finish
% and returns as soon as the driver call does. Legal only for self-ramping
% channels (smdata.inst.type == 1) -- a negative rate on a step channel is
% an error.
% smset always calls the driver. What varies between instruments is whether
% that call starts the ramp or only arms it to await a hardware trigger, and
% for the DecaDACs which of the two happens is set by the per-instrument
% field smdata.inst(i).data.trigmode. See the "Autoramp and Negative Ramp
% Rates" section of README.md for the per-driver table.
% Mainly used by smrun, which derives the negative rate from a negative
% scan.loops(i).ramptime.
% Beware the divider: rangeramp(:,4) is applied to the ramp rate as well as
% the value, after the sign is reapplied and before channels are classified.
% A negative divider therefore inverts the flag -- an autoramp rate becomes
% positive (smset blocks and the trigfn never fires) and an ordinary rate
% becomes negative (a step channel then errors).
%
% After checking that vals and ramprates given are within bounds of
% rangeramp, classifies channels:
%   rampchans (type == 1) have ramping done by the driver.
%   stepchans (type == 0) are stepped every 10 ms to the final value,
%     waiting the correct time for ramprate.
%   setchans (non-finite ramprate) are set straight to the final value.

global smdata;

if isempty(channels) 
    return
end

if ~isnumeric(channels)
    channels = smchanlookup(channels);
end

nchan = length(channels);

if size(vals, 2) > 1 %use vertical list of channels. 
    vals = vals';
end
% could make some variables persistent and add recycling flag argument.

if length(vals) == 1 %if many channels and one value given, all get same value. 
    vals = vals * ones(nchan, 1);
end


rangeramp = vertcat(smdata.channels(channels).rangeramp);
instchan = vertcat(smdata.channels(channels).instchan);

% if ramprate given: 
if exist('ramprate','var') && ~isempty(ramprate)
    if size(ramprate, 2) > 1
        ramprate = ramprate';
    end

    if length(ramprate) == 1 % if many channels and one ramprate given, all get same ramprate. 
        ramprate = ramprate * ones(nchan, 1);
    end

    % check that finite ramprates are smaller than the max given by
    % rangeramp.  
    mask = isfinite(ramprate);
    if any(mask)
        autoramp = sign(ramprate); 
        rangeramp(mask,3) = min(abs(ramprate(mask)), rangeramp(mask, 3));       
        rangeramp(mask,3) = autoramp .* rangeramp(mask,3); % Keep sign for autoramp. 
    end
end
ramprate = rangeramp(:,3); 

%JMN 2020/10/30
if any(vals < rangeramp(:, 1)) || any(vals > rangeramp(:, 2))
    d=warning('query','all');
    if any(regexp(d(1).state,'on'))
        warning('Clipping channels in smset. Check the rangeramp.')
        channels
    else
        fprintf('Clipping channels  in %s in smset. Check the rangeramp.\nAlso, warnings are not enabled. Do you really want this?\n')
        channels
    end
end

% Check that the vals are within rangeramp limits. 
vals = max(min(vals, rangeramp(:, 2)), rangeramp(:, 1));

valsScaled = vals .* rangeramp(:, 4); % scale vals by multiplier 
ramprate = ramprate .* rangeramp(:, 4); % scale ramprate by multiplier


currVals = zeros(nchan, 1);
chantype = zeros(nchan, 1);
ramptime = zeros(nchan, 1);

% Check which channels can be ramped - chantype = 1 is ramping. 
for k = 1:nchan
    chantype(k) = smdata.inst(instchan(k, 1)).type(instchan(k, 2));
end

rampchan = find(chantype == 1);
stepchan = find(chantype == 0);

if any(ramprate(stepchan) < 0)
    error('Negative ramp rate for step channel.');
end
    
setchan = find(~isfinite(ramprate));

% get current val for step channels
for k = stepchan'
    currVals(k)= smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 0]);
end
if isfield(smdata.inst(instchan(1,1)).data,'chansToRamp') %clears instrument data arrays for next use
    smdata.inst(instchan(1,1)).data.chansToRamp  = [];
    smdata.inst(instchan(1,1)).data.valsToRamp = [];
    smdata.inst(instchan(1,1)).data.ratesToRamp  = [];
    smdata.inst(instchan(1,1)).data.Ramp  = [];
end
% start ramps
for k = rampchan' %%QuadDACS are selected with 'chansToRamp' otherwise they go to ramptime 
    if isfield(smdata.inst(instchan(k,1)).data,'chansToRamp') 
        smdata.inst(instchan(k,1)).data.chansToRamp(k,1)  = channels(k); %Places channels in an array
        smdata.inst(instchan(k,1)).data.valsToRamp(k,1)  = valsScaled(k); %Places corresponding values
        smdata.inst(instchan(k,1)).data.ratesToRamp(k,1)  = ramprate(k); %Places corresponding rates
        smdata.inst(instchan(k,1)).data.Ramp(k,1)  = 1;
    else
        ramptime(k) = smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 1], valsScaled(k), ramprate(k));
    end
end



for k = setchan'    
    smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 1], valsScaled(k));
end



if ishandle(999)
    smdispchan(channels([rampchan; setchan]), vals([rampchan; setchan]));
end

if isfield(smdata.inst(instchan(1,1)).data,'chansToRamp')    %send command to ramp all channels at once
    len = length(smdata.inst(instchan(1,1)).data.chansToRamp);
    instrument= (smdata.channels(channels(1,1)).instchan(1,1))*ones(len,1); %Pulls the instrument number and makes it into a column
    smdata.inst(instchan(1, 1)).cntrlfn([instrument,smdata.inst(instchan(1,1)).data.chansToRamp,smdata.inst(instchan(1,1)).data.Ramp], smdata.inst(instchan(1,1)).data.valsToRamp, smdata.inst(instchan(1,1)).data.ratesToRamp);
%%Each instance of smset can only handle one instrument at a time right now
end

dt = .01; %JMN 2022_09_14 changed from 0.01 to 0.05
if isequal(smdata.inst(instchan(1,1)).cntrlfn,@smcSR830) %hacked 9/21/2022, xxc, not working for ramping multiple instr
    dt = 0.2;
end
if isequal(smdata.inst(instchan(1,1)).cntrlfn,@smc3310A) %hacked 9/21/2022, xxc
    dt = 0.2;
end
% step channels - the ramprate is maintained by smset, not through control
% function. 
if ~isempty(stepchan)
    dirStep = (2 * (valsScaled(stepchan) > currVals(stepchan)) - 1); % direction of step. (final value > init, dirStep = 1)
    sizeStep = dt * ramprate(stepchan) .* dirStep; 
    nstep = floor((valsScaled(stepchan)-currVals(stepchan))./sizeStep);
    for i = 1:max(nstep)
        tstep = now;
        currVals = currVals + sizeStep;        
        for k = stepchan(i <= nstep)'; % chans that haven't reach final value
            smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 1], currVals(k));
        end
        
        % update the display every 10 steps. 
        if ishandle(1001) && ~mod(i, 10)
            smdispchan(channels(stepchan(i <= nstep)), currVals(stepchan(i <= nstep))...
                ./rangeramp(stepchan(i <= nstep), 4));
        end

        % wait until dt is reached to maintain ramprate. 
        while (now - tstep) * 24 * 3600 < dt ;end
        
        if ishandle(1000) 
            c = get(1000, 'CurrentCharacter');
            if c == char(27)
                return;
            end
        end
    end
end

%After the last step, set channels to exact final value. 
for k = stepchan'    
    smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 1], valsScaled(k));
end

if ishandle(999)
    smdispchan(channels(stepchan), vals(stepchan));
end
smdata.chanvals(channels) = vals;


% rampchans let the driver do the ramping, but don't return until correct
% time has passed. 
tramp = now;

rampchan = rampchan(ramprate(rampchan) > 0); % For rampchans with ramprate < 0, the driver will ramp. 
ramptime = ramptime(rampchan);
if ~isempty(rampchan)
    pauseTime=max(ramptime) + 24*3600*(tramp - now);
    pause(pauseTime);    
    return; 
    % Next lines appear to use different method, querying the remainder of
    % ramping time through driver. However, not currently used. 
    %[ramptime, ind] = sort(ramptime, 'descend'); 
    %for k = rampchan(ind)'       
    %   t = Inf;
    %    while t > 0
    %        t = smdata.inst(instchan(k, 1)).cntrlfn([instchan(k, :), 2], [], rangeramp(k, 3));
    %        pause(0.8 * t);
    %    end
    %end
end


end

