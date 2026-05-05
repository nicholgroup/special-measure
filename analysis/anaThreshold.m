function [out] = anaThreshold(v_value, filename)
    arguments
        v_value (1,1) double;
        filename {mustBeTextScalarOrCell} = '' 
        % Custom validation for char or cell of char
    end

    og_dir = pwd;
    % If no filename is provided, run smgetfile to obtain it
    if isempty(filename)
        [~,~,filename] = smgetfile('sm*.mat');
    end
    
    if ~iscell(filename)
        filename = {filename};
    end
    
    filepath = {}; fname = {}; ext = {};

    ctab={'r' 'g' 'b' 'c' 'm' 'y' 'k'};
    ctab=[ctab ctab ctab ctab];
    styletab=[repmat({'-'},[1,7]),repmat({'.-'},[1,7]),...
        repmat({'o-'},[1,7]), repmat({'*-'},[1,7])];

    xlabel_char = '';
    out = struct;
    out.biaspt = {};
    figInd = 2233;
    anathrefig = figure(figInd); clf;
    for idx = 1:length(filename)

        [filepath{idx}, fname{idx}, ext{idx}] = fileparts(filename{idx});

        d = load(filename{idx});
        if length(d.scan.loops) >1
            error(['Dimension of the scan is greater that 1: ' fname{idx}])
        end

        if ~iscell(d.scan.loops(1).getchan)
            d.scan.loops(1).getchan={d.scan.loops(1).getchan};
        end
        current_arr = d.data{1}; % y
        voltage_arr = linspace(d.scan.loops.rng(1), ...
            d.scan.loops.rng(2), d.scan.loops.npoints); % x
        gate_name = d.scan.loops.setchan{1};
        xlabel_char = [xlabel_char gate_name ', '];
        
        voltage_threshold = findXThreshold(voltage_arr, current_arr, v_value);
        out.biaspt = [out.biaspt; {gate_name, voltage_threshold}];
            
        hold on;
        plot(voltage_arr,current_arr, [ctab{idx} styletab{idx}], ...
            'DisplayName', fname{idx});
        xline(voltage_threshold, [ctab{idx} styletab{idx}], ...
            'DisplayName', [gate_name ' threshold']);
        hold off;
    
    end

    yline(v_value, '--b', 'DisplayName', ['v_value=' num2str(v_value)])
    title('anaThreshold', 'Interpreter','none')
    xlabel_char(end) = ' '; xlabel_char = [xlabel_char '(V)'];
    xlabel(xlabel_char, 'Interpreter','none');
    ylabel([d.scan.loops.getchan{1} ' (a.u.)'], 'Interpreter','none');
    legend show;
    legend('Location','best', 'Interpreter','none');

    opts=struct();
    opts.file=fname{1};
    opts.body = '';
    opts.title='Data';
    opts.figures=linspace(figInd,figInd,1);
    pptprep(opts);

end

function mustBeTextScalarOrCell(filename)
    if ~(ischar(filename) || (iscell(filename) && all(cellfun(@ischar, filename))))
        error('filename must be a character array or a cell array of character arrays.');
    end
end

function x_threshold = findXThreshold(x, y, v_value)
    % Calculate the absolute difference between y and v_value
    difference = abs(y - v_value);
    
    % Find the index of the minimum difference
    [~, minIndex] = min(difference);
    
    % Find the corresponding x_threshold
    x_threshold = x(minIndex);
    
end
