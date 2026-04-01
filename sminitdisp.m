function sminitdisp
%sminitdisp initializes figure 999 to display current channel values.
% The displayed values of all scalar channels will be updated by every 
% call of smset or smget as long is figure 999 is open.

global smdata;

nchan = length(smdata.channels); %number of channels

%QHF 2022/05/13: make settings more transparent
if nchan > 60 %EJC: 5/19/2022 hack to make sure that we can see full channel list 
    if nchan > 84 %JMN 5/25/22 changed from 80 to 82 on  (YPK changed from 82 to 84)
        lh = 10; %JMN 5/25/22 this might need to be slightly larger. 
        fontsize = 6;
    else
        lh = 12;
        fontsize = 7;
    end
else
    lh = 14; %line height in pixel
    fontsize = 8;
end
num_xpos = 10; %x position of index number string in pixel
name_xpos = 40; %x position of name string in pixel
val_xpos = 140; %x position of value string in pixel
tb_h = 30; %height of figure 999 title bar, necessary for placing the figure right at the top of the screen
fig_w = 260; %width of figure 999
fig_h = (nchan+2)*lh; %height of figure 999

figure(999); clf;

s = get(0,'ScreenSize'); %size of the monitor screen

%[x of bottom left, y of bottom left, width, height] of figure 999
fig_pos_size = [10, s(4)-fig_h-tb_h, fig_w, fig_h]; 
set(999, 'position', fig_pos_size, 'MenuBar', 'none', 'Name', 'Channels');

num_str = cell(1, nchan);
name_str = cell(1, nchan);
for i = 1:nchan
    num_str{i} = sprintf([num2str(i), '. ']);
    name_str{i} = sprintf('%-25s', smdata.channels(i).name);
end

%position and size of text box in figure 999   
uicontrol('style', 'text', 'position', [num_xpos, 10, fig_w-num_xpos-10, fig_h-20], 'FontSize', fontsize,...
    'HorizontalAlignment', 'Left', 'string',  num_str, 'BackgroundColor', [.8 .8 .8]);

uicontrol('style', 'text', 'position', [name_xpos, 10, fig_w-name_xpos-10, fig_h-20], 'FontSize', fontsize,...
    'HorizontalAlignment', 'Left', 'string',  name_str, 'BackgroundColor', [.8 .8 .8]);

smdata.chandisph = uicontrol('style', 'text', 'position', [val_xpos, 10, fig_w-val_xpos-10, fig_h-20], 'FontSize', fontsize,...
    'HorizontalAlignment', 'Left', 'string',  repmat({''}, nchan, 1), 'BackgroundColor', [.8 .8 .8]); 
    
