function [ out ] = anaHall(opts)
%anaHall nalyzes Hall trace data to find mobility and density
%
%Expects to analyze two datafiles with a single getchan, one for the
%transverse voltage, and the other for the longitudinal voltage.
%The hallbar should be current biased, with the current given in scan.data.
%
%opts is a struct with fields
% bmin: min field for mobility analysis
% bmax: max field for mobility analysis


if ~exist('opts','var')
    opts=struct;
    opts.bmax=1;
    opts.bmin=0;
end

fprintf('Select longitudinal voltage file \n')
file=uigetfile('sm*vxx*.mat','MultiSelect','on');
if ~iscell(file)
    file={file}
end

d=load(file{1});

try
    W=d.scan.data.W;
catch
    W=170e-6;
    L=800e-6;
end

try
    Lpp=d.scan.data.Lpp;  
catch
    %Lpp=340e-6;
    %Lpp=170e-6; %careful
end

try
    L=d.scan.data.L; 
    %L=800e-6;
catch
    L=800e-6;
end


try
    current=d.scan.data.current;
catch
    current=input('Enter the current. \n')  
end

vsd=input('Enter the source drain bias. \n');


if size(d.data{1},2)>1 %2D gate vs current sweep
    ind=16; % index of data to plot slices
    
    vsd=d.configvals;
    
    %the first data set is current, and the second dataset is the transverse
    %voltage.
    vxx=d.data{1};
    
    
    vgate=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
    B=linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
    
    figure(220); imagesc(vgate,B,vxx); set(gca,'YDir','norm'); xlabel('Gate voltage'); ylabel('B (T)'); title('Vxx');
    figure(221); clf; hold on; plot(B,abs(vxx(:,ind)./current));
    xlabel('Magnetic field (T)'); ylabel('Rxx');
    
    rxx=vxx./current;
    
    b=B;
    r=abs(rxx(:,end));
    
    
    inds=B<opts.bmax;
    inds=inds.*B>opts.bmin;
    vxx=vxx(inds,:);
    vxx=nanmean(vxx);
    
    
    v2deg=abs(vxx.*L/Lpp);
    R2deg=v2deg./current;
    figure(222); clf;
    plot(vgate,R2deg,'DisplayName','R2deg');
    ax=axis; axis([ax(1) ax(2) 0 1e5]); xlabel('gate voltage'); ylabel('Resistance');
    legend show;
    
    %now the hall data
    fprintf('Select transverse voltage file \n')
    fprintf('Select longitudinal voltage file \n')
    file=uigetfile('sm*vxy*.mat','MultiSelect','on');
    if ~iscell(file)
        file={file}
    end
    
    d=load(file{1});
    vxy=d.data{1};
    
    vgate=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
    B=linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
    g0=(1.6e-19)^2/6.6e-34;
    rxy=vxy./current;
    nu=1./(rxy.*g0); %filling factor
    figure(223); clf; imagesc(vgate,B,rxy); set(gca,'YDir','norm'); xlabel('Gate voltage'); ylabel('B (T)'); title('Vxy');
    figure(224); clf; plot(B,abs(nu(:,ind))); axis([B(1) B(end) 0 20])
    xlabel('Magnetic field (T)'); ylabel('Filling factor (nu)');
    
    figure(111); clf;
    bb=B;
    rr=rxy(:,end);
    [hAx,hLine1,hLine2]=plotyy(b,r,bb,rr);
    
    xlabel('Magnetic field (T)')
    title('Hall data at 10 mK');
    ylabel(hAx(1),'\rho_{xx} (\Omega)') % left y-axis
    ylabel(hAx(2),'\rho_{xy} (\Omega)') % right y-axis
    % set(hAx(1),'YLim',[-50 4000]);
    % set(hAx(2),'YLim',[-50 5000]);
    
    
    inds=B<opts.bmax;
    inds=inds.*B>opts.bmin;
    B=B(inds);
    vxy=vxy(inds,:);
    
    
    
    
    vhall=[];
    %crude measure of Hall voltage. Should
    for i=1:length(vgate)
        P=polyfit(B,vxy(:,i)',1);
        vhall(i)=P(1)*B(end);
        if 0 %plot individual hall traces
            figure(333); clf; hold on;
            plot(B,vxy(:,i)');
            plot(B,polyval(P,B));
            pause(.1);
        end
    end
    %vhall=vxy2-vxy1;
    n=abs(current.*B(end)./(vhall.*1.6e-19)./1e4); %./1e4 converts to per cm^2
    mu=L./(R2deg.*W.*n*1.6e-19);
    mu=abs(Lpp/W.*1./(n.*1.6e-19).*current./vxx);
    rxy=vxy./current;
    %figure(333); clf; waterfall(rxy);
    
    
    
    figure(225); clf;
    subplot(1,3,1)
    plot(vgate,vhall); xlabel('gate voltage'); ylabel(sprintf('Hall voltage at %3.3f',B(end)));
    subplot(1,3,2);
    plot(vgate,n); xlabel('gate voltage'); ylabel('Electron density'); axis([vgate(1) vgate(end) 0 5e12])
    subplot(1,3,3);
    plot(vgate,mu); xlabel('gate voltage'); ylabel('Carrier mobility'); %axis([vgate(1) vgate(end) 0 1e4])
    
    
    popts=struct();
    popts.file=file{1};
    popts.title='Hall data';
    popts.figures=[220 221 222 223 224 225];
    pptprep(popts);
    
end

if size(d.data{1},2)==1

    
    %the first data set is current, and the second dataset is the transverse
    %voltage.
    vxx=d.data{1};
    
    B=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);

    
    figure(220); plot(B,vxx); xlabel('B'); ylabel('Vxx');
        
    rxx=vxx./current;
    
    v2deg=abs(vxx.*L/Lpp);
    R2deg=v2deg./current;
    figure(221); clf; plot(B,R2deg); xlabel('B'); ylabel('R2deg');
    
    %hack alert
    Rtotal=vsd./current;
    R2deg=v2deg./current;
    Rcontact=Rtotal-R2deg;
    figure(222); clf; plot(B,Rcontact); xlabel('B'); ylabel('Rcontact');

    
    %now the hall data
    fprintf('Select transverse voltage file \n')
    file=uigetfile('sm*vxy*.mat','MultiSelect','on');
    if ~iscell(file)
        file={file}
    end
    
    d=load(file{1});
    vxy=d.data{1};
    figure(223); clf; plot(B,vxy); xlabel('B'); ylabel('Vxy');
    

    
    P=polyfit(B,vxy(:)',1);
    vhall=P(1)*B(end);
    
    
    %vhall=vxy2-vxy1;
    n=abs(current.*B(end)./(vhall.*1.6e-19)./1e4); %./1e4 converts to per cm^2
    mu=L./(R2deg.*W.*n*1.6e-19);
    mu=abs(Lpp/W.*1./(n.*1.6e-19).*current./vxx);
    
    popts=struct();
    popts.file=file{1};
    popts.title='Hall data';
    popts.figures=[220 221 222 223];
    popts.body=sprintf('Density is %3.3d and mobility is %3.3d',mean(n),mean(mu));
    pptprep(popts);
    

    
end

end

