function [val] = smcThorlabsPM61C(ico, val, rate)
% 6/2026 FTL
% Driver for Thorlabs PM61C Optical Power Meter — old VISA API (visa/fprintf/query)
% ico(1): instrument index in smdata
% ico(2): channel / parameter to control
    %   1  - Power measurement (W or dBm depending on unit setting)
    %   2  - Power unit        (get/set: 0=Watts, 1=dBm)
    %   3  - Wavelength (nm)   (get/set)
    %   4  - Averaging count   (get/set: 1..5000, sets meas rate = 1000/N Hz)
    %   5  - Bandwidth         (get/set: 0=full ~100kHz, 1=limited ~3Hz)
    %   6  - Power range (W)   (get/set)
    %   7  - Auto-range        (get/set: 0=off, 1=on)
% ico(3): 0=get, 1=set

global smdata

pm = smdata.inst(ico(1)).data.inst;

switch ico(2)
    % --- 1: Power measurement ---
    case 1
        switch ico(3)
            case 0 % get
                val = str2double(query(pm, 'MEAS?'));
            otherwise
                error('PM61C: Power is read-only (ico(3) must be 0)');
        end

    % --- 2: Power unit ---
    case 2
        switch ico(3)
            case 0 % get: returns 0 (W) or 1 (dBm)
                resp = strtrim(query(pm, 'SENS:POW:UNIT?'));
                if strcmpi(resp, 'DBM')
                    val = 1;
                else
                    val = 0;
                end
            case 1 % set: 0=W, 1=dBm
                if val == 1
                    fprintf(pm, 'SENS:POW:UNIT DBM');
                else
                    fprintf(pm, 'SENS:POW:UNIT W');
                end
        end

    % --- 3: Wavelength (nm) ---
    case 3
        switch ico(3)
            case 0 % get
                val = str2double(query(pm, 'SENS1:CORR:WAV?'));
            case 1 % set
                fprintf(pm, 'SENS1:CORR:WAV %d', round(val));
        end

    % --- 4: Averaging count ---
    case 4
        switch ico(3)
            case 0 % get
                val = str2double(query(pm, 'SENS1:AVER?'));
            case 1 % set: accepts integer count or 'low'/'medium'/'high'
                if ischar(val) || isstring(val)
                    switch lower(char(val))
                        case 'low',    n = 1;
                        case 'medium', n = 10;
                        case 'high',   n = 100;
                        otherwise
                            error('PM61C: Unknown averaging preset ''%s''. Use ''low'', ''medium'', ''high'', or a number.', val);
                    end
                else
                    n = round(val);
                end
                fprintf(pm, 'SENS1:AVER %d', n);
        end

    % --- 5: Bandwidth filter ---
    case 5
        switch ico(3)
            case 0 % get: returns 0 or 1
                val = str2double(query(pm, 'INP1:FILT?'));
            case 1 % set: 0=full, 1=limited
                fprintf(pm, 'INP1:FILT %d', val ~= 0);
        end

    % --- 6: Power range (W) ---
    case 6
        switch ico(3)
            case 0 % get current range upper limit (W)
                val = str2double(query(pm, 'SENS:POW:RANG?'));
            case 1 % set manual range
                fprintf(pm, 'SENS:POW:RANG %g', val);
        end

    % --- 7: Auto-range ---
    case 7
        switch ico(3)
            case 0 % get: returns 0 or 1
                val = str2double(query(pm, 'SENS:POW:RANG:AUTO?'));
            case 1 % set: 0=off, 1=on
                fprintf(pm, 'SENS:POW:RANG:AUTO %d', val ~= 0);
        end

    otherwise
        error('PM61C: Unknown channel ico(2) = %d', ico(2));
end

end
