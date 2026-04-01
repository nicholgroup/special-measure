function smConfigureDSI(inst,varargin)
%if actual arguments are passed as a strings, write those to DSI else
%do some basic configuration
%eg. to turn on output: smConfigureDSI(inst, 'OUTP:STAT ON/OFF')
if size(varargin)>0
    for j=1:length(varargin)
        try
        fprintf(inst,varargin{j});
        catch
            error('Could not write %s to DSI',varargin{j});
        end
    end
else
    % identify
    query(inst,'*IDN?');
    % diplay on
    fprintf(inst,'*DISPLAY ON');
    % reset
    %fprintf(inst,'*RST');
    %clear previous errors
    fprintf(inst,'*CLS');
    % make sure the output is off
    fprintf(inst,'OUTP:STAT OFF'); % keep it off
    % buzzer off
    fprintf(inst,'*BUZZER OFF');
    % choice of 10 MHz reference
    fprintf(inst,'SYSREF INT'); %if using external use EXT
    
    % lock to the reference
    fprintf(inst,'SYSREF UPDATE');

end

end