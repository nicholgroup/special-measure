function status = ipscntrl(mode)
%ipscntrl gets the status of an oxford IPS magnet power supply.
%
% status = ipscntrl(mode)
% User control for a magnet power supply
% checks to see if there is an IPS 120 on the rack, if not, check to see if
% there is a Mercury power supply on the rack.
% mode is the command to issue. it can be
    % 'pers': persistent
    % 'ramp': not persistent
    % 'open': open the switch heater (not supported on mercury)
    % 'close': close the switch heater (not supported on mercury
    % 'status': return the status of the power supply
    

% (c) 2010 Hendrik Bluhm.  Please see LICENSE and COPYRIGHT information in plssetup.m.

global smdata;
inst = sminstlookup('IPS 120-10'); % first check if there is an IPS
if ~isempty(inst)
  status=ipscntrl_ips120(mode,smdata.inst(inst).data.inst);
else
  inst = sminstlookup('Mercury IPS');%next check if there is a mercury
  if ~isempty(inst)
      status=ipscntrl_mercury(mode,smdata.inst(inst).data.inst);
  else
     error('cannot find IPS or Mercury supply'); 
  end
end

end

% Subfunction for old-style IPS120 power supplies.
function status=ipscntrl_ips120(mode,inst)

switch mode
    case 'pers'
        smprintf(inst, '%s\r', 'H0');
        smscanf(inst);

        
        smprintf(inst, '%s\r', 'R7');
        curr = smscanf(inst, '%*c%f');
        
        %smprintf(inst, '%s\r', 'R9');
        %rate = smscanf(inst, '%*c%f');
        
        pause(10);
        
        smprintf(inst, '%s\r', 'A2');
        smscanf(inst);
        %pause(60 * abs(curr/rate));
        pause(60 * abs(curr)); % measured 50 s/T.
        
    case 'ramp'
        smprintf(inst, '%s\r', 'A2');
        smscanf(inst);

        smprintf(inst, '%s\r', 'R8');
        curr = smscanf(inst, '%*c%f');
        
        %smprintf(inst, '%s\r', 'R9');
        %rate = smscanf(inst, '%*c%f');
        
        smprintf(inst, '%s\r', 'A1');
        smscanf(inst);
        
        %pause(60 * abs(curr/rate));
        pause(60 * abs(curr));
        
        smprintf(inst, '%s\r', 'H1');
        smscanf(inst);
        %pause(10); 
        
    case 'open'
        smprintf(inst, '%s\r', 'H1');
        smscanf(inst);
        
    case 'close'
        smprintf(inst, '%s\r', 'H0');
        smscanf(inst);

    case 'status'
        
        smprintf(inst, '%s\r', 'X');
        status = smscanf(inst);
end
end

% Subfunction for new-style Mercury power supplies
function status=ipscntrl_mercury(mode,mag)
  status=[];
switch mode
    case 'pers'
        magwrite(mag,'SET:SYS:VRM:ACTN:PERS');
        checkmag(mag);
        while ~ismagpersist(mag)
           pause(3); 
        end
        waitforidle(mag);
        
    case 'ramp'
        magwrite(mag,'SET:SYS:VRM:ACTN:NPERS'); 
        checkmag(mag);
        while ismagpersist(mag)
             pause(5); 
        end
        waitforidle(mag);
        
    case 'open'
        error('operation ''open'' not supported for mercury');
        
    case 'close'
        error('operation ''close'' not supported for mercury');

    case 'status'
        magwrite(mag,'READ:SYS:VRM:ACTN');
        a=fscanf(mag,'%s');
        status=sscanf(a,'STAT:SYS:VRM:ACTN:%s');
        
end
end


% subfunctions for nicely handling mercury communication below
function magwrite(mag,msg)
fprintf(mag,'%s\r\n',msg);
end

function out =ismagpersist(mag)
  magwrite(mag,'READ:SYS:VRM:SWHT');
  state = fscanf(mag,'%s'); 
  sh=sscanf(state,'STAT:SYS:VRM:SWHT:%s');
  
  if isempty(sh)
      error('garbled communication: %s',state); 
  end
  
  offs = strfind(sh,'OFF');
  ons = strfind(sh,'ON');
  
  if length(offs)==3 && isempty(ons)
      out = 1;
  elseif length(ons)==3 && isempty(offs)
      out = 0;
  else
     error('switch heaters not all the same. consider manual intervention. Heater state: %s',state); 
  end
end

function waitforidle(mag)
  magwrite(mag,'READ:SYS:VRM:ACTN');
  a=fscanf(mag,'%s');
  a=sscanf(a,'STAT:SYS:VRM:ACTN:%s');
  while ~strcmp(a,'IDLE')
     pause(1);
     magwrite(mag,'READ:SYS:VRM:ACTN');
     tmp=fscanf(mag,'%s');
     a=sscanf(tmp,'STAT:SYS:VRM:ACTN:%s');
  end
  
end

function checkmag(mag) % checks that communications were valid
  outp=fscanf(mag,'%s');
  if isempty(strfind(outp,'VALID')) && isempty(strfind(outp,'BUSY'))
     error('garbled magnet power communications: %s',outp); 
  end
end