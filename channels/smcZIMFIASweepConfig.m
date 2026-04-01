function scan = smcZIMFIASweepConfig(scan)
%smcZIMFAISweepConfig Summary of this function goes here
%   Detailed explanation goes here
%todo: write a function to update smdata with bstart and bstop, referencing
%the scan. Save the function in Nichol Group/matlab/special meaure/channels

global smdata;

ico=smchaninst(scan.loops(2).getchan); % Get channel name
xypoints=scan.loops(1).npoints;

smdata.inst(ico(1)).data.bstart=scan.loops(1).rng(1);
smdata.inst(ico(1)).data.bstop=scan.loops(1).rng(2);
smdata.inst(ico(1)).data.npts=scan.loops(1).npoints;
smdata.inst(ico(1)).data.nsample=1;%10000;
smdata.inst(ico(1)).data.omegas=150; % unit in dB
%smdata.inst(ico(1)).data.Vtest=0.1; % unit in V %JMN: Let's use special
%measure for this.
scan.loops(1).trafofn=[];

% Try to figure out the bandwidth, tc
% smdata.inst(ico(1)).data.bw = 90;

% Get data back, sub-divide into two parts
scan.loops(2).procfn(1).fn(1).fn=[];
scan.loops(2).procfn(1).fn(1).args={};
scan.loops(2).procfn(1).fn(1).inchan=1;
scan.loops(2).procfn(1).fn(1).outchan=2;

scan.loops(2).procfn(1).fn(2).fn=@subsref;
s=struct(); s.type='()'; s.subs={(1:1:xypoints)};
scan.loops(2).procfn(1).fn(2).args={s};
scan.loops(2).procfn(1).dim=xypoints;

scan.loops(2).procfn(2).fn.fn=@subsref;
s=struct(); s.type='()'; s.subs={(xypoints+1:1:2*xypoints)};
scan.loops(2).procfn(2).fn.args={s};
scan.loops(2).procfn(2).dim=xypoints;

scan.disp(3)=scan.disp(1);
scan.disp(3).channel=2;
scan.disp(4)=scan.disp(2);
scan.disp(4).channel=2;

end

