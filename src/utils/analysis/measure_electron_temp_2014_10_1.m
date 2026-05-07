%% Line scan with RF gates.
qubit='B';
switch qubit
    case 'A'
        chan=[2 1];
        datachan='DAQ1';
    case 'B'
        chan=[3 4];
        datachan='DAQ2';
end


clear pg;
pg.pulses=19;
pg.dict=qubit;
pg.chan=chan;
pg.ctrl='loop pack';  
epsStart=-1;
epsEnd=1;
npulse=200;
%pulse length, measure time, %measure location
pg.params=[2 .75 0 0];
pg.varpar(:,1)=linspace(epsStart, epsEnd, npulse) * dict.exch.val(1);
pg.varpar(:,2)=linspace(epsStart, epsEnd, npulse) * dict.exch.val(2);
pg.name=sprintf('Line_%s_2014_10_1',qubit);
plsupdate(pg);
awgadd(pg.name);
%% Line scans across the leads and junction
sline = tunedata.line.scan;
sline.loops(1).npoints = 512;
sline.consts(1).val = 10e6;
sline.loops(2).npoints=20;

%sline.loops(2).npoints = 64;
sX =sline;
sY = sline;
sX.loops(1).setchan = {'PlsRamp2'};
sX.loops(1).rng = [0 6]*1e-3;
sX.loops(2).npoints=20;

sY.loops(1).setchan = {'PlsRamp1'};
sY.loops(1).rng = [-3 1]*1e-3;
sY.loops(2).npoints=20;


slineRF=fConfSeq2('Line_A_2014_10_1',struct('datachan','DAQ1','nloop',1024,'nrep',64,'opts',''));


%% Run the scans at different MC temps.

MCtemp=smget('MC');
MCtemp=MCtemp{1}*1000;
fprintf('MC temp is %.0f mK\nMeasuring...\n',MCtemp);
namePat=sprintf('A_MC_%.0f_mK',MCtemp);

% name1=(smnext(sprintf('XLead_%s',namePat)));
% d1=smrun(sX,name1);
% figure(56); clf; hold on;
% subplot(2,2,1); plot(nanmean(d1{1})); title('X lead')
% 
% name2=(smnext(sprintf('YLead_%s',namePat)));
% d2=smrun(sY,name2);
% figure(56); subplot(2,2,2); plot(nanmean(d2{1})); title('Y lead')
% 
% name3=(smnext(sprintf('line_%s',namePat)));
% d3=smrun(sline,name3);
% figure(56); subplot(2,2,3); plot(nanmean(d3{1})); title('Line scan')

name4=(smnext(sprintf('lineRF_%s',namePat)));
d4=smrun(slineRF,name4);
figure(56); subplot(2,2,4); plot(nanmean(d4{1})); title('Line scan')

fprintf('##########\nMC temp is %.0f mK \n%s\n%s\n%s\n%s\n##########\n',MCtemp,name1,name2,name3,name4)

sleep;


%%
d=smrun(sX);
d=smrun(sY);
d=smrun(sline);
d=smrun(slineRF);

%% 2015/2/17
chrgScan=tunedata.chrg.scan;
chrgScan.loops(1).npoints=256;
chrgScan.loops(2).npoints=256;

lineScan=tunedata.line.scan;
lineScan.loops(1).npoints=256;
lineScan.loops(2).npoints=32;

%make a scan to go over the (0,1) (0,2) transition
leadScan=tunedata.line.scan;
leadScan.loops(1).setchan='PlsRamp1';
leadScan.loops(1).trafofn=[];
leadScan.loops(1).rng=[0.5e-3 2.5e-3];
leadScan.consts(3).setchan='PlsRamp2';
leadScan.consts(3).val=-4e-3; %-4
leadScan.loops(1).npoints=256;
leadScan.loops(2).npoints=8;
leadScan.loops(1).ramptime=-.02; %.002

mcTemp=cell2mat(smget('MC'));
fprintf('probe temp is %3.0f \n',mcTemp*1e3);
%ramseyScan=fConfSeq2_v2([44 25:43],struct('nloop',64,'nrep',32,'opts','swfb','datachan','DAQ1'));

lineName=sprintf('line_A_%3.0fmK',mcTemp*1e3);
leadName=sprintf('lead_A_%3.0fmK',mcTemp*1e3);
ramseyName=sprintf('ramseyE_A_%3.0fmK',mcTemp*1e3);

%smrun(lineScan,smnext(lineName));
smrun(leadScan,smnext(leadName));
%smrun(ramseyScan,smnext(ramseyName));

snooze;

%% Pulse-based lead scan
clear pg;
pg.pulses=19;
pg.dict='A';
pg.chan=[2,1];
pg.ctrl='loop pack';  
epsStart=-1;
epsEnd=1;
npulse=128;
plen=50;
%pulse length, measure time, %measure location
pg.params=[plen plen-1 0 0]; %want a very long time here.
pg.varpar(:,1)=linspace(-5, -5, npulse); %gate 2, hold this fixed
pg.varpar(:,2)=linspace(3, -3, npulse); %gate 1, vary this one across the lead
pg.name='Lead_A_2014_10_1';
plsupdate(pg);
leadGrp=pg.name;
awgadd(pg.name);

%% make the rf lead scan
leadScanRF=fConfSeq2_v2(leadGrp,struct('nloop',128,'nrep',32,'opts','','datachan','DAQ1'));

mcTemp=cell2mat(smget('MC'));
fprintf('probe temp is %3.0f \n',mcTemp*1e3);
%ramseyScan=fConfSeq2_v2([44 25:43],struct('nloop',64,'nrep',32,'opts','swfb','datachan','DAQ1'));

leadName=sprintf('lead_rf_A_%3.0fmK',mcTemp*1e3);

smrun(leadScanRF,smnext(leadName));

snooze;

%% run scans on a timer with fridge control


tList =[120:20:200 0];
note_str = '';
tstart = tic;
for j = 1:length(tList)
    rsetMCSP_beast(tList(j));
    note_str = [note_str,sprintf('setting MC to %d mK\n',tList(j))];
    fprintf('setting MC to %d mK \n Waiting...\n',tList(j))
    if j>0
        for i = 1:8
            pause(1*60);
            fprintf('%i min >>  ',i*1);
        end
        fprintf('\n');
    end
    
    %TODO: your scan here   
    MCtemp=smget('MC');
    MCtemp=MCtemp{1}*1000;
    fprintf('MC temp is %.0f mK\nMeasuring...\n',MCtemp);
    namePat=sprintf('A_MC_%.0f_mK',MCtemp);
    name4=(smnext(sprintf('lineRF_%s',namePat)));
    d=smrun(slineRF,name4);
    snooze;
    
    if any(isnan(d{1}));break; end;
    fprintf('done with %i of %i in %.2f seconds \n',j,length(tList),toc(tstart));
end
sleep

    