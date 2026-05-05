function [ out ] = anaDrift(file)
% anaDrift(file) analyzes the drift in a data set?

if ~exist('file','var')
    file=smgetfile('sm*Drift*.mat');
end

if ~iscell(file)
    file={file};
end

figure(1234);clf;

out = struct;
out.file = file;

legend_plots = [];

for i=1:length(file)
    d=load(file{i});
    data=d.data{1};
    peak_max = zeros(length(data),1);
    peak_max_ind = zeros(length(data),1);
    for j=1:length(data)
        [peak_max(j), peak_max_ind(j)] = max(abs(data(j,:)));
    end
    x = linspace(0,length(data),length(data));
    yspace = linspace(d.scan.loops(1).rng(1), d.scan.loops(1).rng(2), d.scan.loops(1).npoints);
    y = yspace(peak_max_ind);
    x_space = [];
    y_data = [];
    y_fit_data=[];
    for j=1:length(x)
        if y(j) > yspace(1)
            if y(j) < yspace(length(yspace))
                x_space = [x_space x(j)];
                y_data = [y_data y(j)];
                y_fit_data = [y_fit_data y(j)];
            end
        end
    end
    
    coeffs = polyfit(x_space, y_fit_data, 1);
    % Get fitted values
    fittedX = linspace(min(x_space), max(x_space), length(x_space));
    fittedY = polyval(coeffs, fittedX);
    
    legend_plots = [legend_plots plot(x_space,y_data)];
    hold on
    
    xlabel('Count (approximately 1hr per 500 count)');
    if ~iscell(d.scan.loops(1).getchan)
        ylabel(d.scan.loops(1).getchan);
    else
        ylabel(d.scan.loops(1).getchan{j});
    end
    
    % Plot the fitted line
    plot(fittedX, fittedY, 'r-', 'LineWidth', 2);
    
    out.slope(i) = coeffs(1);
end

legend(legend_plots,file,'Interpreter','none')

end