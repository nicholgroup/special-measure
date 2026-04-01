function s=ana_avg(filename,opts)
%ana_avg(filename,opts) loads data files, plots and returns info about them
% 
% The output struct contains the following information:
% pulsegroups, dBz group, scan, scantime, T1, scaled data, xvals
% It also plots the scaled data, and pops up a PPT dialog
%
% Opts is a struct with the following fields
%   side: can be A or B, is meant to refer to tunedata
%   style: plot style of the graph, i.e.., 'r-'
%   legend: this seems not to be used
%   grps: an array of numbers specifying which groups to plot
%   opts: a string that can include the following.
% 
%   gatesweep -- scan is 1 group repeated while sweeping a gate
%   2d -- include a 2d colorscale plot.
%   subleft, subline, subcol -- handy background subtraction tricks.
%   noplot, noppt, 
%   nodbz -- drop dbz reference.
%   colorplot -- 2d color plot of all data.
%   noscale -- output raw (unrescaled) data 
%   samefig -- plots everything on the same figure
%   offset -- subtracts an offset from the data
%
% Example: ana_avg('',struct('xval',[1:7],'opts','','side','A'))

if ~exist('filename','var') || isempty(filename)
    filename=smgetfile('sm*.mat');
end
if ischar(filename)
    filename={filename};
end

global tunedata;
offset=0;
figs=[];
legs=[];
sind=1;
for ff=1:length(filename)
    tmp=load(filename{ff});
    s(ff).filename=filename{ff};
    s(ff).scan=tmp.scan;
    s(ff).scantime=getscantime(tmp.scan,tmp.data);

    if length(tmp.scan.data.pulsegroups) == 1 && ndims(tmp.data{1}) == 2
      for j=1:length(tmp.data)          
        s(ff).data{j}=reshape(tmp.data{j},[size(tmp.data{j},1),1,size(tmp.data{j},2)]);
      end
    else
      s(ff).data=tmp.data;
    end
    
    s(ff).scan.data.prettyname=regexprep(filename{ff},'(sm_)|(\.mat)','');
    

    if ~exist('opts','var') || isempty(opts)
        opts.opts='';
    elseif ischar(opts)        
        opts=struct('opts',opts);
    end
    opts = def(opts,'side',{tunedata.name});
    for ss=1:length(opts.side)
        s(ff).t1(ss) = att1(opts.side{ss},s(ff).scantime,'after');
    end
    opts=def(opts,'style',{'r-','g-','b-','c-','m-','y-','k-'});
    opts=def(opts,'legend','prettyname');
    opts=def(opts,'opts','samefig hold');
    opts=def(opts,'grps',[]);
    opts=def(opts,'scalingopts',''); % added 12/2/2020 XXC
    opts.dbz=find(cellfun(@(p) ~isempty(p),regexp({s(ff).scan.data.pulsegroups.name},'[dD][bB][zZ]')));
    opts.nodbz = setdiff(1:length(s(ff).scan.data.pulsegroups),opts.dbz);
    
    if isempty(opts.grps)
        opts.grps = 1:length(s(ff).scan.data.pulsegroups);
        if isopt(opts,'nodbz')          
          opts.grps=setdiff(opts.grps,opts.dbz);
        end
    elseif length(opts.grps) == 2
       if isinf(opts.grps(2))
           opts.grps=opts.grps(1):length(s(ff).scan.data.pulsegroups);
       end       
    end
    s(ff).grps=opts.grps;
    if ~isopt(opts,'noplot')
        if isopt(opts,'samefig')
            figure(1);
            figs=unique([figs 1]);
        else
            figs=unique([figs ff]);
            figure(ff);
        end
        if isopt(opts,'hold')
            hold on;
        else
            clf;
        end
    end
    
    sz=size(s(ff).data{1});
    if isfield(opts,'xval') && ~isempty(opts.xval)
        try
            s(ff).xv = mat2cell(opts.xval);
        catch
            s(ff).xv = {opts.xval};%2019/02/25 YPK hack to plot spin shuttle
        end
    
    else
        
        try
    for j=1:length(s(ff).scan.data.pulsegroups)
      s(ff).xv{j}=guessxv(s(ff).scan.data.pulsegroups(j).name,s(ff).scantime,s(ff).scan,j);
    end
        catch
            s(ff).xv{j}=(1:1:size(s(ff).data{j},3));
        end
    end
    s(ff).tv = guesstv({s(ff).scan.data.pulsegroups(opts.nodbz).name},s(ff).scantime,s(ff).scan);
    channels=0;
    for i=1:length(s(ff).data)
               szs = size(s(ff).data{i});
        if all(size(szs) == size(sz)) && all(szs == sz) % This is apparently data.
            channels=channels+1;
        end
    end
    uchan=0;
    
%     if ~isopt(opts,'noscale') % Scale data
%             s(ff).data=anaHistScale(s(ff).scan,s(ff).data,s(ff).t1);
%     end
    if ~isopt(opts,'noscale') % added 12/2/2020 for scalingopts, XXC
        if isempty(opts.scalingopts)
            s(ff).data=anaHistScale(s(ff).scan,s(ff).data,s(ff).t1);
        else
            s(ff).data=anaHistScaleV4(s(ff).scan,s(ff).data,s(ff).t1,opts.scalingopts,'','randplot'); 
        end
    end
    for i=1:length(s(ff).data)
        szs = size(s(ff).data{i});
        if all(size(szs) == size(sz)) && all(szs == sz) % This is apparently data.
            if ~isopt(opts,'noplot')
                figure(10+i);                
                rdata=reshape(permute(s(ff).data{i},[1 3 2]),szs(1),szs(2)*szs(3));
                imagesc(rdata);colorbar;
            end
            
            uchan=uchan+1;
            if ~isopt(opts,'noplot')
                figure(1);
                %subplot(1,channels+1,uchan); why channels+1?
                 subplot(1,channels,uchan);

            end
            if isopt(opts,'gatesweep')
                legs=linspace(s(ff).scan.loops(1).rng(1),s(ff).scan.loops(1).rng(2),s(ff).scan.loops(1).npoints);
                s(ff).legs=legs;
            else
                legs=s.tv;
                if isempty(legs)
                    legs=1:size(s(ff).data{i},2);
                end
            end
            
            if isempty(opts.grps)
                opts.grps=1:length(s(ff).scan.data.pulsegroups);
            end
            for k=opts.nodbz
                if isfield(opts,'frames') && ~isempty(opts.frames)
                  s(ff).d{i} = squeeze(nanmean(s(ff).data{i}(opts.frames,k,:),1));
                else                    
                  s(ff).d{i} = squeeze(nanmean(s(ff).data{i}(:,k,:),1));
                end
                if isfield(s(ff).scan.data,opts.legend)
                    leg=s(ff).scan.data.(opts.legend);
                elseif isopts(opts,'gatesweep')
                    leg=legs(k);
                else
                    leg=s(ff).scan.data.prettyname;
                end
                if isnumeric(leg)
                    leg=sprintf('%g',leg);
                end
                if isopt(opts,'center')
                    fo = mean(s(ff).d{i});
                else
                    fo=0;
                end
                if ~isopt(opts,'noplot')
                    %figure(400); %EJC 2021/03/12 - added to make sure imagesc plot and line plots are not on same figure
                    %hold on; %QHF 2021/07/07: why hold? Do we not want to clear figure before plotting new data?
                    %JMN  2021/07/20 something is not right about the above code. Commenting out.
                    %clf; %XXC 8/16/2022 commented out. Already taken care around line 92. Ohterwise, 'hold' won't work.
                    plot(s(ff).xv{min(k,end)},s(ff).d{i}+offset-fo,opts.style{mod(sind-1,end)+1},'DisplayName',leg);
                end
                sind=sind+1;
                if isopt(opts,'offset')
                    offset=offset + mean([std(s(ff).d{i}),range(s(ff).d{i})]);
                end
            end
            if ~isopt(opts,'noplot')
               legend show; 
            end
            
            
            if ~isopt(opts,'nodbz') % Plot dBz data 
            for k=opts.dbz
                figure(4);
                hold on; 
                title('dBz groups');
                if isfield(opts,'frames') && ~isempty(opts.frames)
                  s(ff).d{i} = squeeze(nanmean(s(ff).data{i}(opts.frames,k,:),1));
                else                    
                  s(ff).d{i} = squeeze(nanmean(s(ff).data{i}(:,k,:),1));
                end
                if isfield(s(ff).scan.data,opts.legend)
                    leg=s(ff).scan.data.(opts.legend);
                elseif isopts(opts,'gatesweep')
                    leg=legs(k);
                else
                    leg=s(ff).scan.data.prettyname;
                end
                if isnumeric(leg)
                    leg=sprintf('%g',leg);
                end
                if isopt(opts,'center')
                    fo = mean(s(ff).d{i});
                else
                    fo=0;
                end
                if ~isopt(opts,'noplot')
                  hold on;                    
                  plot(s(ff).xv{min(k,end)},s(ff).d{i}+offset-fo,opts.style{mod(sind-1,end)+1},'DisplayName',leg);
                end
                sind=sind+1;
                if isopt(opts,'offset')
                    offset=offset + mean([std(s(ff).d{i}),range(s(ff).d{i})]);
                end

            end
            end
            if isopt(opts,'2d')
                figure(99);
                clf;
                z=squeeze(nanmean(s(ff).data{i},1));
                z=z(opts.grps,:);
                if isopt(opts,'subline')
                   z=z-repmat(mean(z,2),1,size(z,2)); 
                end
                if isopt(opts,'subleft')
                   z=z-repmat(z(:,1),1,size(z,2)); 
                end
                if isopt(opts,'subcol')
                   z=z-repmat(mean(z,1),size(z,1),1); 
                end
                if isopt(opts,'plane')
                   coeff=fit_plane(z);
                   [mx,my]=meshgrid(1:size(z,2),1:size(z,1));
                   z=z-mx*coeff(1)-my*coeff(2)-coeff(3); 
                end
                if isfield(opts,'smooth')
                    z=filter(z,opts.smooth);
                end                
                %imagesc(s(ff).xv{end},legs,z);
                imagesc(s(ff).xv{end},legs,z);
                colorbar;
                set(gca,'YDir','norm');

                s(ff).z=z;
                
                figs=[99 figs];
            end
                
        end
    end
    if ~isopt(opts,'noplot') % Show Legend 
        legend('off');
        s(ff).l=legend('show');
        set(s(ff).l,'Interpreter','none');
    end
end
if ~isopt(opts,'noppt') % Pop up PPT dialogue
    opts=struct();
    opts.file=filename{1};
    opts.body = '';
    opts.title=s(1).scan.data.prettyname;
    opts.figures=figs;
    pptprep(opts);
          
%      ppt=guidata(pptplot);     
%      set(ppt.e_file,'String',filename{1});     
%      set(ppt.e_figures,'String',['[',sprintf('%d ',figs),']']);     
%      set(ppt.e_title,'String',s(1).scan.data.prettyname);
%      set(ppt.e_body,'String','');     
%      set(ppt.exported,'Value',0);
  end
end

function xv=guessxv(grpname,scantime,s,grpind)
try %use information stored in scan.data
    xv=s.data.pulsegroups(grpind).xval;
catch
    xv=plsinfo('xval',grpname,[],scantime);
end
dxv=sum(diff(xv,[],2),2);
[dm,di]=max(dxv);
if dm == 0
    fprintf('Warning: no xval variation\n');
    di=1; 
end
xv=xv(di,:);
end

function tv=guesstv(grps,scantime,s)
  xvo=[];  
  if length(grps) == 1
      tv=0;
      return;
  end
  for j=1:length(grps)
      try
          xv=s.data.pulsegroups(j).xval;
      catch
          xv=plsinfo('xval',grps{j},[],scantime);
      end
      m=1;
      for k=1:size(xv,1)
          if all(xv(k,:) == xv(k,1))
              xvo(j,m)=xv(k,1);
              m=m+1;
          end
      end      
      if m==1 % auto-fallback on params. 
          try
              xv=s.data.pulsegroups(j).params;
          catch
              xv=plsinfo('params',grps{j},[],scantime);
          end
          for q=1:length(xv(:))
            xvo(j,q)=xv(q);
          end
      end
  end
  dxv=sum(diff(xvo,[],1) ~= 0,1);
  [dm,di]=max(dxv);
  if dm == 0
    fprintf('Warning: no xval variation\n');
    di=1; 
  end
  tv=xvo(:,di);
end

% Apply a default.
function s=def(s,f,v)
if(~isfield(s,f))
    s=setfield(s,f,v);
end
end

function b=isopt(config,name)
b=~isempty(strfind(config.opts,name));
end


function se=cull(data)
m = median(data(:));
s = median(abs(data(:)-m));
se = find(abs(data(:)-m) < 2*s);
m = mean(data(se));
se = find(abs(data(:)-m) < 2*s);
end

function coeff=fit_plane(data)
data=data(~any(isnan(data),2),:);
[gx,gy] = gradient(data);
sm=2;
for l=1:size(gx,1)
    gx(l,:)=smooth(gx(l,:),3);
end
for l=1:size(gy,2)
    gy(:,l)=smooth(gy(:,l),3);
end
coeff(1)=median(gx(cull(gx)));
coeff(2)=median(gy(cull(gy)));
coeff(3)=mean(mean(data));
end


function out=filter(data, sigma)
if (~exist('sigma','var'))
    sigma=3;
end
%fprintf('Sigma is %g\n',sigma);
wid=sigma;
if length(wid) == 1
    wid=[wid wid];
end
ks=max(5,floor(max(sigma)*3/2)*2+1);
ks;
kw=floor(ks/2);
kc=ceil(ks/2);
kw;
[x y]=meshgrid(-kw:kw,-kw:kw);
kernel=exp(-(x.*x)./(2*wid(1)*wid(1)) - (y.*y)/(2*wid(2)*wid(2)));
kernel=kernel / sum(kernel(:));
out=filter2(kernel,data);
remove=3;
out([(1:remove) (end-remove:end)],:)=nan;
out(:,[(1:remove) (end-remove:end)])=nan;
end

