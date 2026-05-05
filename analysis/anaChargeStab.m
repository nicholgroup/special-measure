function [out ] = anaChargeStab(file)
%Analysis 2D charge stability diagram
%   JHD 09/08/24

amp_threshold = 0.05e-3;
Gaussian_filter_sigma = 0.1;


if ~exist('file','var')
    file=uigetfile('sm*.mat','MultiSelect','on');
end

if ~iscell(file)
    file={file};
end

ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
ctab=[ctab ctab ctab ctab];
styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];

out=struct;
d=load(file{1});

if ~iscell(d.scan.loops(1).getchan)
    d.scan.loops(1).getchan={d.scan.loops(1).getchan};
end

for i=1:length(file)
    d=load(file{i});
    
    xvals=linspace(d.scan.loops(1).rng(1),d.scan.loops(1).rng(2),d.scan.loops(1).npoints);
    yvals=linspace(d.scan.loops(2).rng(1),d.scan.loops(2).rng(2),d.scan.loops(2).npoints);
    for j=1:length(d.data)
        figInd=222+(i-1)*length(d.data)+(j-1);
        figure(figInd); clf;
        if length(size(d.data{j}))==3
            subplot(2,1,1);
            %imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1))));
            x_axis_grad = diff(squeeze(nanmean(d.data{j},1)),1,1);
            % y_axis_grad = diff(squeeze(nanmean(d.data{j},1)),1,2);
            % imagesc(xvals,yvals,edgeDetection2D(nanmean(d.data{j},1), 1)); %derivative in y direction
            %imagesc(xvals,yvals,diff(squeeze(nanmean(d.data{j},1)),1,2)); %derivative in x direction

            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
%             colormap(gca,'parula'); % JHD 08/03/24
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            subplot(2,1,2);
            imagesc(xvals,yvals,squeeze(nanmean(d.data{j},1)));
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
%             colormap(gca,'parula');
            c=colorbar;
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            
        elseif length(size(d.data{1}))==2
            subplot(2,1,1);

            imagesc(xvals,yvals,edgeDetection2D(d.data{j},...
                amp_threshold, Gaussian_filter_sigma))

            % imagesc(xvals,yvals,edgeDetectionLoG(d.data{j},...
            %     amp_threshold, Gaussian_filter_sigma))

            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            
            set(gca,'YDir','norm');
            c=colorbar;
            mycmap = [
                253/255, 231/255, 37/255;
                94/255, 201/255, 98/255;
                33/255, 145/255, 140/255;
                59/255. 82/255. 139/255;
                61/255, 1/255, 84/255;   

                253/255, 231/255, 37/255;
                94/255, 201/255, 98/255;
                33/255, 145/255, 140/255;
                59/255. 82/255. 139/255;
                61/255, 1/255, 84/255; 
                
                253/255, 231/255, 37/255;
                94/255, 201/255, 98/255;
                33/255, 145/255, 140/255;
                59/255. 82/255. 139/255;
                61/255, 1/255, 84/255; 
            ];
            mycmap = interp1(linspace(0, 1, size(mycmap, 1)), mycmap, linspace(0, 1, 128));
            colormap(gca,'jet')
            caxis([-1, 1]);
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            subplot(2,1,2);
            imagesc(xvals,yvals,d.data{j});
            xlabel(d.scan.loops(1).setchan);
            ylabel(d.scan.loops(2).setchan);
            title(file{i},'Interpreter','none');
            set(gca,'YDir','norm');
            c=colorbar;
            colormap(gca,'parula');
            try
                ylabel(c,d.scan.loops(1).getchan{j});
            catch
                ylabel(c,d.scan.loops(1).getchan);        
            end
            
        else
            error('Unrecognized data size');
        end
        
    end
    out(i).data=d.data{1};
    out(i).diffdata=diff(d.data{j});
    out(i).xlabel=d.scan.loops(1).setchan;
    out(i).ylabel=d.scan.loops(2).setchan;
    out(i).xvals=xvals;
    out(i).yvals=yvals;
    out(i).scan=d.scan;
    
end


opts=struct();
opts.file=file{1};
opts.title='Data';
opts.figures=linspace(222,figInd,figInd-222+1);
pptprep(opts);
end


function finalMap = edgeDetection2D(data, threshold, sigma)
    % Step 0: Apply Gaussian filter to smooth the input data
    data = imgaussfilt(data, sigma); % sigma controls the amount of smoothing

    % Step 1: Compute the gradient along the x direction (horizontal)
    gradX = diff(data, 1, 2); % Difference along columns (2nd dimension)
    
    % Step 2: Compute the gradient along the y direction (vertical)
    gradY = diff(data, 1, 1); % Difference along rows (1st dimension)
    
    % Step 3: Pad gradients to match original size (because diff reduces size by 1)
    gradX = padarray(gradX, [0 1], 'replicate', 'post'); % Pad along columns
    gradY = padarray(gradY, [1 0], 'replicate', 'post'); % Pad along rows

    % Step 4: Thresholding the gradients to filter flat regions
    gradX(abs(gradX) < threshold) = 0;
    gradY(abs(gradY) < threshold) = 0;

    % Step 5: Sum the absolute values of gradients to get the final edge map
    gradMagnitude = gradX + gradY;

    % Step 6: Normalize the final edge map for better visualization
    finalMap = gradMagnitude / max(abs(gradMagnitude(:))); % Normalize to [0,1]
end


function finalMap = edgeDetectionLoG(data, threshold, sigma)
    % Step 0: Apply Gaussian filter to smooth the input data
    dataSmoothed = imgaussfilt(data, sigma); % Gaussian smoothing with sigma
    
    % Step 1: Apply Laplacian filter to the smoothed data
    laplacianKernel = fspecial('log', [5 5], sigma); % Laplacian of Gaussian kernel
    laplacianFiltered = imfilter(dataSmoothed, laplacianKernel, 'replicate');
    
    % Step 2: Detect zero-crossings in the Laplacian filtered image
    zeroCrossingMap = edge(dataSmoothed, 'zerocross', [], laplacianKernel);
    
    % Step 3: Normalize the zero-crossing map for better visualization
    finalMap = zeroCrossingMap .* laplacianFiltered;
    finalMap = finalMap / max(abs(finalMap(:))); % Normalize to [0,1]

    % Step 4: Apply threshold to filter out weak edges (optional)
    if threshold > 0
        finalMap(abs(finalMap) < threshold) = 0;
    end
    finalMap = abs(finalMap);
end

