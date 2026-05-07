function smatrigAWG(inst)
%function smatrigAWG(inst)
%set AWG triggers CH1M1, CH3M1
%for AWG5000: High (2.6 V), then Low (0.0 V). 
%for AWG5200: High (1.55 V), then Low (0.0 V).

if ~exist('inst','var') || isempty(inst)
    % inst = sminstlookup('AWG5000');
    error('Please specify AWG instrument.');
end
global smdata;

device = smdata.inst(inst).device;
switch device
    case 'AWG5000'
        highvolt = 2.6;
    case 'AWG5200'
        highvolt = 1.55; %EJC why is this 1.55V rather than max allowed 1.75V???
    otherwise
        error('Incorrect AWG instrument, please check smdata');
end
    
% fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:HIGH 2');
% 
% fprintf(smdata.inst(inst).data.inst, sprintf('SOUR1:MARK1:VOLT:LOW %d', highvolt));
% fprintf(smdata.inst(inst).data.inst, sprintf('SOUR3:MARK1:VOLT:LOW %d', highvolt));
% fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0');
% fprintf(smdata.inst(inst).data.inst, 'SOUR3:MARK1:VOLT:LOW 0');
% 
%fprintf(smdata.inst(inst).data.inst, sprintf('SOUR1:MARK1:VOLT:LOW %d;:SOUR3:MARK1:VOLT:LOW %d', highvolt,highvolt));
%fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0;:SOUR3:MARK1:VOLT:LOW 0');

%2021/04/16 EJC: give each fridge it's own triggers. For now, washington
%has it's own and all the other fridges have the same - just add more cases
%to if statement below to add individual control for each fridge
if strcmp(smdata.name,'Washington')
%     fprintf(smdata.inst(inst).data.inst, sprintf('SOUR1:MARK1:VOLT:LOW %d;:SOUR3:MARK1:VOLT:LOW %d', highvolt, highvolt));
%     fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0;:SOUR3:MARK1:VOLT:LOW 0');
    fprintf(smdata.inst(inst).data.inst, sprintf('SOUR1:MARK1:VOLT:LOW %d;:SOUR4:MARK1:VOLT:LOW %d', highvolt, highvolt));
    fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0;:SOUR4:MARK1:VOLT:LOW 0'); 
    % 05/17/2022 HY: Changed the decadac trigger channel and marker as high
    % volt output path of channel 3 is defective. I don't know if the
    % trigger is also affected but didn't want take a risk.
else
    fprintf(smdata.inst(inst).data.inst, sprintf('SOUR1:MARK1:VOLT:LOW %d;:SOUR3:MARK1:VOLT:LOW %d ;:SOUR3:MARK2:VOLT:LOW %d', highvolt,highvolt,highvolt));
    fprintf(smdata.inst(inst).data.inst, 'SOUR1:MARK1:VOLT:LOW 0;:SOUR3:MARK1:VOLT:LOW 0;:SOUR3:MARK2:VOLT:LOW 0');
end

