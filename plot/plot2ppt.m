%%
% User Options
fignum =gcf; %figure number to be saved; gcf is handy
data.slidetitle = 'Right Dot Jprime Calibrartion'; % slide title
data.body = 'After Oliver Tuned It';
data.comments = '';
% =======Don't mess with things below this line =====
if 1
    %scan that file came from
    if ~exist('scanfile','var') scanfile=''; end
    [s p]=uigetfile('sm_*.mat','Scan to Associate with Figure',scanfile);
    scanfile = [ p s];
    
    % Make up a clever file name, use the previous monday
    path='z:\qDots\ppt\ppt_1010\';
    dtm=0;  % Days in past for last monday
    while datestr(now-dtm,'d') ~= 'M'
        dtm = dtm + 1;
    end
    data.pptsavefile = [ path datestr(now-dtm,'yyyy-mm-dd') ];
    
    for f=fignum                        
        fplot2ppt(f, scanfile, data);
    end
end