function out = findThresh2D(file)
%analyzes screening gate scans


%%%%%%%%% SET UP
%get file
figInd=200;
if ~exist('file','var')
    [~,~, file] = smgetfile('sm*.mat');
end

%turn file into cell array
if ~iscell(file)
    file={file};
end

d = load(file{1}); %load file
n1 = d.scan.loops(1).npoints; %x dimension of data
n2 = d.scan.loops(2).npoints; %y dimension of data
totalI = abs(d.data{1}); % store current
V1 = linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),n1); %store X voltage
V2 = linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),n2); %store Y voltage

dimI = size(totalI); %store dimension of I
maxI = max(abs(totalI),[],'all'); %store max current

%predefine vars 
threshV = zeros(dimI(1)+dimI(2),2);
threshI1 = zeros(1,dimI(1));
threshI2 = zeros(1,dimI(2));

satV = zeros(dimI(1)+dimI(2),2);
satI1 = zeros(1,dimI(1));
satI2 = zeros(1,dimI(1));

%%%%%%%%% THRESHOLDS and SATURATION  Values for 1st gate %%%%%%%%%%%%%%%%%%%



for i = 1:dimI(1)
    %isolates row
    I = totalI(i,:);    
    
    %find threshold
    if min(I) < (1*(10^(-11))) %checks if device is already on
        store_data.x = V1;
        store_data.y = I;
        try
            temp = findThresh2(store_data);
            threshV(i,2) = V2(i);
            threshV(i,1) = temp.threshV;
            threshI1(i) = temp.threshI;
        catch
            continue
        end
    end
    
    %calculate saturation
    for j = 1:length(I)
        if I(j) < (maxI*0.8)
            satI1(i) = I(j);
            satV(i,1) = V1(j);
            satV(i,2) = V2(i);
            break
        else
            continue
        end
    end
end
clf

%%%%%%%%% THRESHOLDS and SATURATION  Values FOR 2ND GATE %%%%%%%%%%%%%%%%%

for i = dimI(1)+1:dimI(1)+dimI(2)
    %isolates one column
    I = totalI(:,i-dimI(1));    
    
    %find lower threshold
    if abs(min(I)) < (1*(10^(-11))) %checks if device is already on
        store_data.x = V2;
        store_data.y = I;
        try
            temp = findThresh2(store_data);
            threshV(i,2) = temp.threshV;
            threshV(i,1) = V1(i-dimI(1));
            threshI2(i-dimI(1)) = temp.threshI;
        catch
            continue
        end
    end
    
    %find saturation
    for j = 1:length(I)
        if I(j) < (maxI*0.8)
            satI2(i) = I(j);
            satV(i,2) = V2(j);
            satV(i,1) = V1(i-dimI(1));
            break
        else
            continue
        end
    end
end
clf

% ************* Remove zeros  ************
threshV(find(threshV(:,1)==0),:)=[];
threshV(find(threshV(:,2)==0),:)=[];

satV(find(satV(:,1)==0),:)=[];
satV(find(satV(:,2)==0),:)=[];

% **** sort *****
[threshV(:,2), sInd] = sort(threshV(:,2), 'ascend');
threshV(:,1) = threshV(sInd,1);

[satV(:,2), sInd] = sort(satV(:,2), 'ascend');
satV(:,1) = satV(sInd,1);

%check for switch 
if 1
    smthPoint=1;
    %figure(figInd);clf;figInd=figInd+1;
    %plot(smooth(threshV(:,1),smthPoint), threshV(:,2),'*'); hold on;
    %plot(smooth(satV(:,1),smthPoint), satV(:,2),'*');     
    [xcounts,xcenters] = hist(smooth(satV(:,1)),10);
    [~,maxBin] = max(xcounts);
    if maxBin==10
        checkSwitch = 0;
    else
        checkSwitch = 1;
    end
end


%%%%%%%%% FIT PARABOLAS
smoothPoint=5;
fitData1=smooth(threshV(:,1), smoothPoint);
fitData2 =smooth( threshV(:,2), smoothPoint);

%fit using fit
if 1
    p = polyfit(fitData1,fitData2,2);
    f = polyval(p,fitData1);
    V0s = [fsolve(@(x) (p(1)*x^2 + p(2)*x + p(3)-min(V1)+abs(max(satV(1)))),0.2),fsolve(@(x) (p(1)*x^2 + p(2)*x + p(3)-min(V2)+abs(max(satV(2)))),0.2)];
end


% channel line on V1-V2 space: tangent to threshold and passing through
% intersection between h and v lines

chLine1 = @(x) -1/p(2).*x +   ( V0s(1) + V0s(2)/p(2) );

% channel line on V1-V2 space:  passing through origin of V1-V2(0,0) and intersection between h and v lines
p0=0;%min(min(V1), min(V2)); 
chLine2 = @(x)  (V0s(2) - p0)/(V0s(1) - p0).*x  


%%%%%%%%% 2D PLOTTING

figure(figInd); clf; subplot(1,2,1)
imagesc(V1,V2,totalI); 
set(gca,'YDir','norm');colorbar;
hold on;
lineWidth=2;
%plot threshold fit
plot(fitData1,f, 'LineWidth',lineWidth,'color','c','DisplayName','Threshold fit' );
line([min(V1), max(V1)], [V0s(2),V0s(2)],'LineWidth',lineWidth,'color','r','DisplayName',['V2=', num2str(V0s(2))]);%plot threshold defined boundary-1
line( [V0s(1),V0s(1)],[min(V2), max(V2)],'LineWidth',lineWidth,'color','m','DisplayName',['V1=', num2str(V0s(1))]);%plot threshold defined boundary-2

chV2= chLine2(V1);%channel V2
plot(V1, chV2, 'LineWidth',lineWidth,'color','g','DisplayName','Channel line' );


legend show;


% find channel current along channel line
chanCur=[];
chInd2=[];
for i=1:length(chV2)
    [~,chInd2(i)]=min(abs(V2-chV2(i))) ;
    chanCur(i) = totalI(i,chInd2(i));
end
plot(V1, V2(chInd2), '*', 'DisplayName','Channel points');

xlabel('V1');
ylabel('V2');


subplot(1,2,2);hold on;
plot(V1, chanCur, 'd');
xlabel('V1');
ylabel('Current along channel line');


%FIND POINT


chData.y = chanCur;
chData.x = V1;

%alternate fit


f2 = @(x) p(1).*(x.^2) + p(2).*x + p(3) - (V0s(2) - p0)/(V0s(1) - p0).*x;
intersect = fsolve(f2,mean([min(V1);V0s(1)]));

for i = 1:length(chData.x)
    if chData.x(length(chData.x) - i) > intersect+0.25*(V0s(1)-intersect)
        setI = chData.y(length(chData.x) - i);
        setV1 = chData.x(length(chData.x) - i);
        setV2 = chV2(length(chData.x) - i);
        subplot(1,2,1); hold on;
        plot(setV1,setV2,'k*','DisplayName','Set Current');
        subplot(1,2,2);hold on;
        plot(setV1,setI,'k*','DisplayName','Set Current');
        break
    else
        continue
    end
end

out.V1 = setV1;
out.V2 = setV2;

end
