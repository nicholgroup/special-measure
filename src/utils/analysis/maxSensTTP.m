%Finds the max sensitivity from TTvP scan (for setting up sensor dot)

d=anaChrg2;
maxes = nanmax(d.xdiffdata,[],2);
[maxv indmax] = nanmax(maxes);

try
    t1 = d.scan.loops(2).setchan{1};
    t2 = d.scan.loops(2).setchan{2};
    d.scan.loops(2).trafofn.args
    offst = ans{1};
catch %so that can run on scans with only one setchan in loop 2
    t1 = d.scan.loops(2).setchan;
    t2 = '';
    offst = 0;
end
    
figure(222);
subplot(1,2,1); hold on;
plot([min(d.xvals) max(d.xvals)],[d.yvals(indmax) d.yvals(indmax)],'r--');
subplot(1,2,2); hold on;
plot([min(d.xvals) max(d.xvals)],[d.yvals(indmax) d.yvals(indmax)],'r--');

display(['set ' t1 '=' num2str(d.yvals(indmax)) ' and ' t2 '=' num2str(d.yvals(indmax)+offst)]);

