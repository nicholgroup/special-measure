function [out] = anaVNA(file)
%anaVNA plots a spectrum from the old HP VNA.

og_dir = pwd;

if ~exist('file','var')
    fprintf('Select data file.\n')
    [~,~, file]=smgetfile('sm*.mat');
    %file=uigetfile('sm*.mat','MultiSelect','on'); EJC: 5/3/18 replace with
    %smgetfile to be able to load from any directory
end

[filepath, filename, ext] = fileparts(file);

d=load(file);

freqs=linspace(d.data{2}(1),d.data{3}(1),d.data{4}(1));
mags=squeeze(nanmean(d.data{1}));

figInd=444;
figure(figInd); clf; hold on;
plot(freqs,10*log10(mags));
xlabel('Frequency');
ylabel('Power (dB)');

cd(filepath);
opts=struct();
opts.file=filename;
% opts.path=filepath{1};
opts.title='SAW Data';
opts.figures=444;
pptprep(opts);

cd(og_dir);

end


