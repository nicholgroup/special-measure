function inst = smcSantecTSL775Setup(visa_address)
% Example:
%   smdata.inst(end+1) = smcSantecTSL775Setup('GPIB0::1::INSTR');
  % n = length(smdata.inst);
  % smaddchannel(n, 1, 'Wavelength_TSL',  [1490 1630 Inf 1]);  % ramp rate MUST be Inf
  % smaddchannel(n, 2, 'Power_TSL',       [-5 13 Inf 1]);
  % smaddchannel(n, 3, 'PowerActual_TSL');
  % smaddchannel(n, 4, 'Output_TSL',      [0 1 Inf 1]);
inst.data.inst = smcSantecTSL775Init(visa_address);
inst.datadim   = ones(4, 1);
inst.cntrlfn   = @smcSantecTSL775;
inst.type      = zeros(4, 1);
inst.device    = 'SantecTSL775';
inst.name      = 'TSL';
inst.channels  = char({'Wavelength', 'Power', 'PowerActual', 'Output'});
end
