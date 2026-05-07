function [ out ] = fitCoulombPeak(fit_type,file)
% fitCoulombPeak fits a transport peak.
%
%[ out ] = fitCoulombPeak(fit_type,file)
% plot and fit Coulomb Peak and calculate derivative. find location for right, left,
% base, and peak
%
%
%
% fit_type takes 'asym', 'sym', or 'cosh' or 'bw'



if ~exist('file','var')
    file=uigetfile('sm*.mat');
end

out = struct;


% LOAD COULOMB PEAK DATA
d = load(file);
Vaxis = linspace(d.scan.loops.rng(1),d.scan.loops.rng(2),d.scan.loops.npoints);
Vdata = d.data;
Vdata = Vdata{1};

% FIT COULOMB PEAK, CALCULATE dI/dV, FIND LOCATIONS OF THE COULOMB PEAK AND THE PEAKS IN dI/dV

format long;

xv=Vaxis; yv=Vdata; 

% QHF 2018/05/02: 
% 1. account for non-zero baseline using histogram
% 2. if the peak height is lower than thrshld then fitting is ignored (for
% DC measurement ~1e-11, for AC measurement ~5e-12

[n,edges]=histcounts(Vdata,40);
[~,baseind]=max(n);
baseline=edges(baseind);

ignore=0;
thrshld=0.8e-11;

if max(abs(yv-baseline))<thrshld
    ignore=1;
end

if ignore==0
    
    %Fit both positive and negative current peaks
    if abs(max(yv-baseline))>abs(min(yv-baseline))
        [m ind]=max(yv-baseline);
        p=[baseline m+baseline Vaxis(ind) 0.0007 2 0.001 2]; %should more intelligently choose peak width
    else
        [m ind]=min(yv-baseline);
        p=[baseline m+baseline Vaxis(ind) 0.0007 2 0.001 2];
    end
    
    
    % QHF 2018/03/19: Sometimes fitting coefficients are returned to be compelx
    % numbers. Force beta to be real and ignore imaginary parts
    
    % QHF 2018/05/03: Fit twice to obtain more reasonable fit and beta
    
    
    switch fit_type
        case 'asym' %antisymmetric fit
            fitfn=@(p,xv) antiSymPeak(p,xv);
            beta=fitwrap('plinit plfit',xv,yv',p,fitfn);
            beta=real(beta);
            beta=fitwrap('plinit plfit',xv,yv',beta,fitfn);
            beta=real(beta);
        case 'sym' %symmetric fit
            fitfn=@(p,x) p(1)+p(2).*exp(-((abs(x-p(3))./p(4)).^p(5)));
            p=p(1:5);
            beta=fitwrap('plfit plinit',xv,yv',p,fitfn);
            beta=real(beta);
            beta=fitwrap('plinit plfit',xv,yv',beta,fitfn);
            beta=real(beta);
        case 'cosh' %cosh function
            fitfn=@(p,x) p(1)+p(2).*cosh(((x-p(3)))/(p(4))).^(-2);
            p=p(1:4);
            beta=fitwrap('plfit plinit',xv,yv',p,fitfn);
        case 'bw' % Breit-Wigner (for magnetic field measurements)
            fitfn=@(p,x) p(1) + abs(1i*p(2).*((p(4)/2))./(x-p(3)+1i*(p(4)./2)));
            p=p(1:4);
            beta=fitwrap('plfit plinit',xv,yv',p,fitfn);
    end
    
    
    fitdata=fitfn(beta,xv);
    V0 = beta(3);
    
    [mp ind_p] = max(abs(fitdata-baseline)); %top of the peak
    mp = mp+baseline;
    
    dIdV=diff([eps;fitdata(:)])./diff([eps;xv(:)]);
    figure(777); clf; plot(xv,dIdV);
    
    [m1 ind1] = min(dIdV);
    [m2 ind2] = max(dIdV);
    
    %DETERMINE THE LEFT AND THE RIGHT POINT
    if ind1<ind2
        ind_l=ind1; m_l=m1;
        ind_r=ind2; m_r=m2;
    else
        ind_l=ind2; m_l=m2;
        ind_r=ind1; m_r=m1;
    end
    
    if strcmp(fit_type,'bw')
        ind_b = 5;
    else
        ind_b = 5;
%         ind_b = ind_l-round(4*abs(ind_r-ind_l));%%%%THIS FINDS THE BASELINE POINT BY MOVING 2.5 TIMES THE DISTANCE BETWEEN SIDE LOCATIONS OFF THE LEFT LOCATION TO THE LEFT (MAY NEED TO BE ADJUSTED)
%         if ind_b<=0
%             ind_b=5;
%         end
    end
    
    
    
    
    pointID = {'right','left','base','peak'};
    mdIdV = [m_r, m_l, 0, 0];
    xpoints = [xv(ind_r), xv(ind_l), xv(ind_b), xv(ind_p)];
    ypoints = [yv(ind_r), yv(ind_l), yv(ind_b), yv(ind_p)];
    xpointsfit = [xv(ind_r), xv(ind_l), xv(ind_b), V0];
    ypointsfit = [fitdata(ind_r), fitdata(ind_l), fitdata(ind_b), fitdata(ind_p)];
    sz = 100;
    figure(500); hold on; scatter(xpoints(1),ypoints(1),sz,'MarkerEdgeColor',[0 .5 .5],'MarkerFaceColor',[1 0 0],'LineWidth',1.5,'DisplayName','Right');
    figure(500); hold on; scatter(xpoints(2),ypoints(2),sz,'MarkerEdgeColor',[0 .5 .5],'MarkerFaceColor',[1 1 0],'LineWidth',1.5,'DisplayName','Left');
    figure(500); hold on; scatter(xpoints(3),ypoints(3),sz,'MarkerEdgeColor',[0 .5 .5],'MarkerFaceColor',[1 0 1],'LineWidth',1.5,'DisplayName','Base');
    figure(500); hold on; scatter(xpoints(4),ypoints(4),sz,'MarkerEdgeColor',[0 .5 .5],'MarkerFaceColor',[0 1 0],'LineWidth',1.5,'DisplayName','Peak');
    figure(500); hold on; scatter(xpointsfit,ypointsfit,'k','HandleVisibility','off');
    legend show;
    out.beta = beta;
    out.xdata = xv;
    out.ydata = yv;
    out.xfit = xv;
    out.yfit = fitdata;
    out.dIdVfit = dIdV;
    out.pointID = pointID;
    out.xpoints = xpoints;
    out.ypoints = ypoints;
    out.xpointsfit = xpointsfit;
    out.ypointsfit = ypointsfit;
    out.mdIdV = mdIdV;
   
end

out.ignore=ignore;

end


