function sminitdisp_ejc
% function sminitdisp_ejc
% Initialize figure 999 to display current channel values.
% The displayed values of all scalar channels will be updated by every
% call of smset or smget as long is figure 999 is open.


global smdata;
nchan = length(smdata.channels);

try
    colors = {smdata.channels.color}; 
catch
    colors = cell(1,length(smdata.channels));
end

figure(999); clf;
s=get(0,'ScreenSize');
set(999, 'position', [10, s(4)-15*nchan, 265, 14*nchan+20], 'MenuBar', 'none', ...
    'Name', 'Channels');

num_str = cell(1, nchan);
name_str = cell(1, nchan);
for i = 1:nchan
    num_str{i} = sprintf([num2str(i), '. ']);
    name_str{i} = sprintf('%-25s', smdata.channels(i).name);
end

uicontrol('style', 'text', 'position', [10, 10, 220, 14*nchan], 'FontSize', 8,...
    'HorizontalAlignment', 'Left', 'string',  num_str, 'BackgroundColor', [.9 .9 .9]);

for i=1:nchan
    hh = uicontrol('style', 'text', 'position', [40, 10, 220, 14*(nchan-((i-1)))], 'FontSize', 8,...
        'HorizontalAlignment', 'Left', 'string',  name_str{i}, 'BackgroundColor', [.9 .9 .9]);
    if ~isempty(colors{i})
        set(hh,'ForegroundColor',colors{i});  % its  for all rows in same colour
    else
        set(hh,'ForegroundColor',[0 0 0]);  % its  for all rows in same colour
    end
end

smdata.chandisph = uicontrol('style', 'text', 'position', [140, 10, 100, 14*nchan], 'FontSize', 8,...
    'HorizontalAlignment', 'Left', 'string',  repmat({''}, nchan, 1), 'BackgroundColor', [.9 .9 .9]);
