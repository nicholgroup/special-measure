function [returnVal]=smConfigTSGv1(TSGname,cntrl)
%TSGname: name of TSG unit in smdata
%cntrl is struct with fields:
%RF - turn on or off RF, could be on or off
%MODL - Sets or queries the enable state of modulation
%TYPE - modulation type, could be AM, FM, PM, Pulse, QAM, CPM, VSB
%STYP - modulation sub-type, could be ANALOG, VECTOR, DEFAULT1BIT, DEFAULT2BIT
%MFNC - modulation function, could be SINE, RAMP, TRIANGLE, SQUARE, NOISE, %EXTERNAL, USERWAVEFORM
%RATE - Sets or queries the modulation rate, default unit-Hz, should be a
        %floating point value
%ADEP - Sets or queries the AM modulation depth {d} in percent, should be a
        %floating point value between 0 and 100;
%FDEV - Sets or queries the FM deviation. If omitted, units default to Hz.

%PFNC - Sets or queries the modulation function for pulse modulation, could be SQUARE, NOISE, EXTERNAL, USERWAVEFORM

%PPER - Sets or queries the pulse modulation period. If omitted, units default to seconds

%PWID - Sets or queries the pulse modulation width (duty cycle). This value controls pulse
        %modulation when the selected waveform is square. Units default to seconds
        
%

%2021/2 YPK
%eg: smcTSGv1('MW1',struct('RF','on','STYP','ANALOG','TYPE','AM');
%YPK: 2021/4/20 added case to send same commands on more than one SG simultaneously

global smdata
%find object index in smdata.inst
if ~iscell(TSGname)
    TSGname={TSGname};
end

nTool=[];
for iTSG=1:length(TSGname)
    tmp= strcmp({smdata.inst(:).name},TSGname{iTSG});
    nTool(iTSG)=find(tmp);
end

% find control names 
cntrlNames=fieldnames(cntrl);
nCntrl=numel(cntrlNames);

%test comunication 
for iTSG=1:length(nTool)
    try
        query(smdata.inst(nTool(iTSG)).data.inst,'*IDN?');
    catch
        error('%s (TSG4106A) communication error!',smdata.inst(nTool(iTSG)).name);
    end
end
returnVal=cell(length(nCntrl),1+length(nTool));%return value for query
for k=1:nCntrl%loop over control    
    counter=1;
    
    for iTSG=1:length(nTool)
        while ~query(smdata.inst(nTool(iTSG)).data.inst,'*OPC?')
            pause(1/100);%
            counter=counter+1;
            if counter>=1000
                error('OPC error \n ');
            end
        end
    end
    
    switch cntrlNames{k}
        
        case {'RF','rf'} %RF on/off
            cmnd{1}='ENBR';
            cmnd{2}='%d';
            cmnd{3}=0;%default query
            switch cntrl.RF
                case {'ON','on'}
                    cmnd{3}=1;
                case {'OFF','off'}
                    cmnd{3}=0;
                case {'?',''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    Warning('Wrong RF field value, turning RF off \n');
            end
        case {'MODL','modl'} %modulation on/off
            cmnd{1}='MODL';
            cmnd{2}='%d';
            cmnd{3}=0;%default off
            switch cntrl.MODL
                case {'ON','on'}
                    cmnd{3}=1;
                case {'OFF','off'}
                    cmnd{3}=0;
                case {'?',''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    Warning('Wrong modulation control field value, turning modulation off \n');
            end
            
        case {'STYP','styp'}  %modulation analog or digital
            cmnd{1}='STYP';
            cmnd{2}='%d';
            cmnd{3}=0;%default analog
            
            switch cntrl.STYP
                case {'analog','ANALOG'}
                    cmnd{3}=0;
                case {'digital','DIGITAL'}
                    cmnd{3}=1;
                case {'default1bit', 'DEFAULT1BIT'}
                    cmnd{3}=2;
                case {'default2bit', 'DEFAULT2BIT'}
                    cmnd{3}=3;
                case {'?'.''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    error('Wrong STYPE field value \n');
            end
            
        case {'TYPE','type'}%modulation type
            cmnd{1}='TYPE';
            cmnd{2}='%d';
            cmnd{3}=0;%default AM
            switch cntrl.TYPE
                case {'AM','am'}
                    cmnd{3}=0;
                case {'FM','fm'}
                    cmnd{3}=1;
                case {'PM','pm'}
                    cmnd{3}=2;
                case {'PULSE','pulse'}
                    cmnd{3}=4;
                case {'QAM','qam'}
                    cmnd{3}=7;
                case {'COM','com'}
                    cmnd{3}=8;
                case {'VSB','vsb'}
                    cmnd{3}=9;
                case {'?',''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    cmnd{2}='%s';
                    cmnd{3}='?';
                    warning('Invalid TYPE value, returning the query \n');
            end
            
        case {'MFNC','mfnc'}%modulation function, default sine wave
            cmnd{1}='MFNC';
            cmnd{2}='%d';
            cmnd{3}=0;%default sine
            switch cntrl.MFNC
                case {'SINE','sine'}
                    cmnd{3}=0;
                case {'RAMP','ramp'}
                    cmnd{3}=1;
                case {'TRIANGLE','triangle'}
                    cmnd{3}=2;
                case {'SQUARE','square'}
                    cmnd{3}=3;
                case {'NOISE','noise'}
                    cmnd{3}=4;
                case {'EXTERNAL','external'}
                    cmnd{3}=5;
                case {'USERWAVEFORM','userwaveform'}
                    cmnd{3}=11;
                case {'?',''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    %cmnd{2}='%s';      cmnd{3}='?';
                    warning('Invalid modulation function value, setting default sine wave \n');
                    
            end
            
        case {'RATE','rate'}%modulation rate, unit used: Hz, default 1 Hz
            cmnd{1}='RATE';
            cmnd{2}='%f';
            cmnd{3}=1;%default rate is 1Hz
            if ~isempty(cntrl.RATE) && ~ischar(cntrl.RATE)
                cmnd{3}=cntrl.RATE;
            elseif strcmp(cntrl.RATE,'?')
                cmnd{2}='%s';   cmnd{3}='?';
            else
                cmnd{2}='%s';   cmnd{3}='?';
                warning('Invalid rate value, returning query value \n');
                
            end
            
        case {'ADEP','adep'} %Sets or queries the AM modulation depth {d} in percent.
            cmnd{1}='ADEP';
            cmnd{2}='%f';
            cmnd{3}=100.0;%default depth 100%
            if ~isempty(cntrl.ADEP) && ~ischar(cntrl.ADEP)
                cmnd{3}=cntrl.ADEP;
            elseif strcmp(cntrl.ADEP,'?')
                cmnd{2}='%s';   cmnd{3}='?';
            else
                cmnd{2}='%s';   cmnd{3}='?';
                warning('Invalid AM modulation depth value, returning query value \n');
                
            end
            
        case{'FDEV','fdev'}%Sets or queries the FM deviation. If omitted, units default to Hz
            cmnd{1}='FDEV';
            cmnd{2}='%f';
            cmnd{3}=0.0;%default FDEV 0
            if ~isempty(cntrl.FDEV) && ~ischar(cntrl.FDEV)
                cmnd{3}=cntrl.FDEV;
            elseif strcmp(cntrl.FDEV,'?')
                cmnd{2}='%s';   cmnd{3}='?';
            else
                warning('Invalid FM deviation, setting it to zero \n');
                
            end
            
        case {'PFNC','pfnc'}%modulation function, default external
            cmnd{1}='PFNC';
            cmnd{2}='%d';
            cmnd{3}=5;%default external
            switch cntrl.PFNC
                case {'SQUARE','square'}
                    cmnd{3}=3;
                case {'NOISE','noise'}
                    cmnd{3}=4;
                case {'EXTERNAL','external'}
                    cmnd{3}=5;
                case {'USERWAVEFORM','userwaveform'}
                    cmnd{3}=11;
                case {'?',''}
                    cmnd{2}='%s';
                    cmnd{3}='?';
                otherwise
                    %cmnd{2}='%s';      cmnd{3}='?';
                    warning('Invalid pulse modulation function type, setting default external source\n');
                    
            end
            
        case{'PPER','pper'}%Sets or queries the pulse modulation period. If omitted, units default to S
            cmnd{1}='PPER';
            cmnd{2}='%f';
            cmnd{3}=0.0;%default pper 0
            if ~isempty(cntrl.PPER) && ~ischar(cntrl.PPER)
                cmnd{3}=cntrl.PPER;
            elseif strcmp(cntrl.PPER,'?')
                cmnd{2}='%s';   cmnd{3}='?';
            else
                warning('Invalid pulse modulation period, setting it to zero \n');
                
            end
            
        case{'PWID','pwid'}%Sets or queries the pulse modulation width. Units second
            cmnd{1}='PWID';
            cmnd{2}='%f';
            cmnd{3}=0.0;%default pulse modulation width
            if ~isempty(cntrl.PWID) && ~ischar(cntrl.PWID)
                cmnd{3}=cntrl.PWID;
            elseif strcmp(cntrl.PWID,'?')
                cmnd{2}='%s';   cmnd{3}='?';
            else
                warning('Invalid pulse modulation width, setting it to zero \n');
                
            end
                
    end
    if ~isempty(cmnd{3})&& ~strcmp(cmnd{3},'?')
        %send commands one by one
        for iTSG=1:length(nTool)
            try
                fprintf(smdata.inst(nTool(iTSG)).data.inst,sprintf([cmnd{1} cmnd{2}],cmnd{3}));
            catch
                error('Failed to set value on %s \n',smdata.inst(nTool(iTSG)).name);
            end
            %query and return the state of instrument            
            returnVal{k,1+iTSG}=query(smdata.inst(nTool(iTSG)).data.inst,[cmnd{1}, '?']);
        end
    end
    returnVal{k,1}=cmnd{1};
end
end

