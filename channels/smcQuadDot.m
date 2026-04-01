function [val, rate ] = smcQuadDot(ico, val, rate )
% driver for quadruple quantum dot
% channels for this instrument are mu1, mu2, mu3, mu4
% ico is a three element vector. ico(1) is the instrument number. ico(2) is
% the channel number. ico(3) is the operation.
% 1: mu1
% 2: mu2
% 3: mu3
% 4: mu4
% general operation codes are
% 0: get
% 1: set
% 2: get buffered data
% 3: trigger
% 4: arm
% 5: configure
% ramping not yet configured for this device.


% TODO: make cases for multiple channels ramping at once
global smdata

c=smdata.inst(ico(1)).data.matrix;
mu0=smdata.inst(ico(1)).data.mu0;

debug1=0; %for rates
debug2=0; %for diff

switch ico(3)
    
    case 0 %get
        gateChans=smchanlookup(smdata.inst(ico(1)).data.gateNames);
        gateVals=cell2mat(smget(gateChans));
        muVals=c*gateVals'+mu0';
        val=muVals(ico(2));

    case 1 %set
        
        gateChans=smchanlookup(smdata.inst(ico(1)).data.gateNames);
        gateVals=smdata.inst(ico(1)).data.gateVals;
        realGateVals=cell2mat(smget(gateChans));
        diff=abs(gateVals-realGateVals);
        
        if debug2
            diff
        end
        
        if any(diff>2e-4) % hard coded threshold, decaDac resolution is ~6e-5
            gateVals=realGateVals;
            warning('Large gate value difference (>0.2mV), using real gate values.');
        end
        
        muVals=c*gateVals'+mu0';       
        
        muValsNew=muVals;
        muValsNew(ico(2))=val;
        
        dMu=muValsNew-muVals;
        time=abs(dMu(ico(2))/rate);
        
        gateValsNew=inv(c)*(muValsNew-mu0'); 
        
        dG=gateValsNew-gateVals';
        
        rates=abs(dG/time).*sign(rate);
        
        rates(abs(dG)<1e-6)=.5;
        
        if debug1
            if rate<0
                rate
            end
        end
        
        %Need to have different rates for the different channels
        smset(gateChans,gateValsNew,rates);
        smdata.inst(ico(1)).data.gateVals = gateValsNew';
                 
end



end

%TO Do
% hard code ramprate!