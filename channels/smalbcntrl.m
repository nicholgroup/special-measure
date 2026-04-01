function val = smalbcntrl(insts, opt)
% function val = smcLabBrick(insts, opt)
% inst is the inst number of name of the lab brick (fix me use sminstlookup)
% Control function for LabBricks from Vaunix.
% inst can be a cell array of insts.
% opt can contain any of:
%   on  - turn the RF on
%  off  - turn the RF off
% init  - save the current lab-brick state as the power-on default.
% list  - list serials of attached bricks

global smdata;

if ~iscell(insts) && ~isnumeric(insts)
  insts={insts};
end

for i=1:length(insts)
    inst=sminstlookup(insts(i));
    
    if ~isempty(strmatch(opt,'list'))
        smcLabBrick_v2([inst 12 1], 1, inf);
    end
    
    if ~isempty(strmatch(opt,'on'))
        smcLabBrick_v2([inst 3 1], 1, inf);
    end
    
    if ~isempty(strmatch(opt,'off'))
        smcLabBrick_v2([inst 3 1], 0, inf);
    end
    
    if ~isempty(strmatch(opt,'init'))
        smcLabBrick_v2([inst 4 1], 0, inf);
    end
    
end

end
