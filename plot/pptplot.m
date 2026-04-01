function varargout = pptplot(varargin)
% PPTPLOT M-file for pptplot.fig
%      PPTPLOT, by itself, creates a new PPTPLOT or raises the existing
%      singleton*.
%
%      H = PPTPLOT returns the handle to a new PPTPLOT or the handle to
%      the existing singleton*.
%
%      PPTPLOT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PPTPLOT.M with the given input arguments.
%
%      PPTPLOT('Property','Value',...) creates a new PPTPLOT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before pptplot_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to pptplot_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help pptplot

% Last Modified by GUIDE v2.5 19-Aug-2011 11:58:59

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @pptplot_OpeningFcn, ...
                   'gui_OutputFcn',  @pptplot_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before pptplot is made visible.
function pptplot_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to pptplot (see VARARGIN)

% Choose default command line output for pptplot
handles.output = hObject;
set(hObject,'Name','PPT Export');
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes pptplot wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = pptplot_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function e_title_Callback(hObject, eventdata, handles)
% hObject    handle to e_title (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_title as text
%        str2double(get(hObject,'String')) returns contents of e_title as a double
set(handles.exported,'Value',0);

% --- Executes during object creation, after setting all properties.
function e_title_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_title (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function e_body_Callback(hObject, eventdata, handles)
% hObject    handle to e_body (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_body as text
%        str2double(get(hObject,'String')) returns contents of e_body as a double
set(handles.exported,'Value',0);

% --- Executes during object creation, after setting all properties.
function e_body_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_body (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.

%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function e_comments_Callback(hObject, eventdata, handles)
% hObject    handle to e_comments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_comments as text
%        str2double(get(hObject,'String')) returns contents of e_comments as a double
set(handles.exported,'Value',0);

% --- Executes during object creation, after setting all properties.
function e_comments_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_comments (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function e_file_Callback(hObject, eventdata, handles)
% hObject    handle to e_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_file as text
%        str2double(get(hObject,'String')) returns contents of e_file as a double
set(handles.exported,'Value',0);

% --- Executes during object creation, after setting all properties.
function e_file_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_file (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in b_choose.
function b_choose_Callback(hObject, eventdata, handles)
% hObject    handle to b_choose (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[t p]=smgetfile('sm*.mat','Scan File to Export',char(get(handles.e_file,'String'))); 
%[t p]=uigetfile('sm*.mat','Scan File to Export',char(get(handles.e_file,'String')));
if strcmp(p,pwd)
  set(handles.e_file,'String',t);
else
  set(handles.e_file,'String',[p t]);
end
set(handles.exported,'Value',0);

function e_figures_Callback(hObject, eventdata, handles)
% hObject    handle to e_figures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of e_figures as text
%        str2double(get(hObject,'String')) returns contents of e_figures as a double
set(handles.exported,'Value',0);

% --- Executes during object creation, after setting all properties.
function e_figures_CreateFcn(hObject, eventdata, handles)
% hObject    handle to e_figures (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in export.
function export_Callback(hObject, eventdata, handles)

% hObject    handle to export (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

fignum=get(handles.e_figures,'String');
fignum=eval(['[' fignum ']']); 
data.slidetitle = char(get(handles.e_title,'String'));
data.body = char(get(handles.e_body,'String'));
data.comments = char(get(handles.e_comments,'String'));;
set(handles.exported,'Value',1);
scanfile=char(get(handles.e_file,'String'));
% =======Don't mess with things below this line =====
% Make up a clever file name, use the previous monday
%path='z:\qDots\ppt\ppt_0711\';
currDir=pwd;
dirs=regexp(currDir,'\\\w*'); %looks for the subdirectories you're in 

dirName=currDir(1:dirs(end));
path=[dirName 'ppt\'];
% dirName=currDir(dirs(end)+6:end);
% % if ~strfind(dir,'data') 
% %     path='z:\qDots\ppt\ppt_2014_02_27\';
% %     fprintf('You are not in a data directory, putting in MX50 PPT \n'); 
% % else 
% if currDir(dirs(end)+1:dirs(end)+4)~='data'
%     dirName = currDir(dirs(end-1)+6:dirs(end)-1);
% end
% path=sprintf('Z:\\qDots\\PPT\\ppt_%s\\', dirName); 
% if ~exist(path,'dir')
%     path='z:\qDots\PPT\ppt_2015_11_05\';
% end
if ~exist(path,'dir')
    dirName=currDir(1:dirs(end-1))
    path=[dirName 'ppt\']
end


%path='z:\qDots\ppt\ppt_2014_02_27\';
dtm=0;  % Days in past for last monday
while datestr(now-dtm,'d') ~= 'M'
    dtm = dtm + 1;
end
data.pptsavefile = [ path datestr(now-dtm,'yyyy-mm-dd') ];
try
  for f=fignum        
    fplot2ppt(f, scanfile, data);
  end
catch err;
   warndlg(sprintf('PPT Export Failed: (%s) %s',err.identifier,err.message),'PPT Export','modal'); 
   rethrow(err);
   
  
end



% --- Executes on button press in exported.
function exported_Callback(hObject, eventdata, handles)
% hObject    handle to exported (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of exported
