function varargout = RF_explorer(varargin)
% RF_EXPLORER M-file for RF_explorer.fig
%      RF_EXPLORER, by itself, creates a new RF_EXPLORER
%
%      H = RF_EXPLORER returns the handle to a new RF_EXPLORER
%
%      RF_EXPLORER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in RF_EXPLORER.M with the given input arguments.
%
%      RF_EXPLORER('Property','Value',...) creates a new RF_EXPLORER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before RF_explorer_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to RF_explorer_OpeningFcn via varargin.
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help RF_explorer

% Last Modified by GUIDE v2.5 19-Apr-2012 17:33:35

%% -- Initialisation code

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
   'gui_Singleton',  gui_Singleton, ...
   'gui_OpeningFcn', @RF_explorer_OpeningFcn, ...
   'gui_OutputFcn',  @RF_explorer_OutputFcn, ...
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

%% -- Opening and output functions

% --- Executes just before RF_explorer is made visible.
function RF_explorer_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to RF_explorer (see VARARGIN)

% Choose default command line output for RF_explorer
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes RF_explorer wait for user response (see UIRESUME)
% uiwait(handles.figRFExplorer);

% - Load data from file or from arguments
if (nargin < 1)
   error('RFEXPLORER:USAGE', '*** RF_explorer: Incorrect usage');
end

disp('--- RF_explorer: Loading data and pre-computing...');

if (ischar(varargin{1}))
   if (exist(varargin{1}, 'file'))
      try
         load(varargin{1}, 'fsStack', 'vnNumPixels', 'fPixelOverlap', ...
            'fPixelSizeDeg', 'vfScreenSizeDeg', 'vfBlankStds', 'mfStimMeanResponses', ...
            'mfStimStds', 'mfRegionTraces', 'tfTrialResponses', 'tnTrialSampleSizes', ...
            'sRegionsPlusNP', 'tBlankStimTime');
         
      catch mErr
         me = MException('RFEXPLORER:LOADERROR', '*** RF_explorer: Could not load analysis data from file');
         me.addCause(mErr);
         destroy(hObject);
         throw(me);
      end
   end
   
else
   % - Load data from command line
   if (nargin < 5)
      error('RFEXPLORER:USAGE', '*** RF_explorer: Incorrect usage');
   end
   
   [fsStack, vnNumPixels, fPixelOverlap, fPixelSizeDeg, vfScreenSizeDeg, ...
      vfBlankStds, mfStimMeanResponses, mfStimStds, mfRegionTraces, ...
      tfTrialResponses, tnTrialSampleSizes, sRegionsPlusNP, tBlankStimTime] = varargin{:};
end

% - Assign data to GUIDATA
handles.fsStack = fsStack;
handles.vnNumPixels = vnNumPixels;
handles.fPixelOverlap = fPixelOverlap;
handles.fPixelSizeDeg = fPixelSizeDeg;
handles.vfScreenSizeDeg = vfScreenSizeDeg;
handles.vfBlankStds = vfBlankStds;
handles.mfStimMeanResponses = mfStimMeanResponses;
handles.mfStimStds = mfStimStds;
handles.mfRegionTraces = mfRegionTraces;
handles.tfTrialResponses = tfTrialResponses;
handles.tnTrialSampleSizes = tnTrialSampleSizes;
handles.sRegionsPlusNP = sRegionsPlusNP;
handles.tBlankStimTime = tBlankStimTime;
guidata(hObject, handles);


% -- Populate listbox with ROIs, select neuropil

nNumROIs = numel(sRegionsPlusNP.PixelIdxList);
for (nROI = 1:nNumROIs)
   cROIList{nROI} = num2str(nROI); %#ok<AGROW>
end
set(handles.lbROIList, 'String', cROIList, 'Value', 1);

% - Write filenames into GUI
[nul, cstrFilenames] = cellfun(@fileparts, handles.fsStack.cstrFilenames, 'UniformOutput', false);
strFilenames = ['Files: {' sprintf('''%s'', ', cstrFilenames{:}) '}'];
set(handles.txtFilenames, 'String', strFilenames);

% - Call drawing function
RFE_UpdateFigures(hObject, handles);

% - Set focus to ROI list
uicontrol(handles.lbROIList);


% --- Outputs from this function are returned to the command line.
function varargout = RF_explorer_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


%% -- Main figure update function

function RFE_UpdateFigures(hObject, handles)

% - Get an overview image, if necessary
if (~isfield(handles, 'tfOverviewImage'))
   handles.tfOverviewImage = MakeOverviewImage(handles.fsStack);
   [handles.vtGlobalTime, handles.vnBlockIndex, ...
      handles.vnFrameInBlock, handles.vtTimeInBlock, ...
      handles.vnStimulusSeqID, handles.vtTimeInStimPresentation, ...
      handles.vnPresentationIndex, handles.vbUseFrame] = ...
      handles.fsStack.FrameStimulusInfo(1:size(handles.fsStack, 3));
   guidata(hObject, handles);
end

% - Plot the overview image and scale bar
cla(handles.ax2PImage);
image(handles.tfOverviewImage, 'Parent', handles.ax2PImage);
set(handles.figRFExplorer ,'CurrentAxes', handles.ax2PImage)
PlotScaleBar(handles.fsStack.fPixelsPerUM, 25, 'tr', 'w-', 'LineWidth', 5, 'Parent', handles.ax2PImage);

% - Add ROI annotations
vnLabelRegions = get(handles.lbROIList, 'Value');
sContourRegions = handles.sRegionsPlusNP;
sContourRegions.NumObjects = nnz(vnLabelRegions);
sContourRegions.PixelIdxList = sContourRegions.PixelIdxList(vnLabelRegions);

mnLabelMatrix = labelmatrix(sContourRegions) > 0;

if (~all(mnLabelMatrix(:) == mnLabelMatrix(1)))
   hold on;
   contour(handles.ax2PImage, mnLabelMatrix', .5, 'LineWidth', 2);
end

for (nRegion = reshape(vnLabelRegions, 1, []))
   vnStackSize = size(handles.fsStack, 1:2);
   [y, x] = ind2sub(vnStackSize, handles.sRegionsPlusNP.PixelIdxList{nRegion});
   text(mean(y), mean(x), num2str(nRegion), ...
      'FontSize', 12, 'FontWeight', 'bold', 'VerticalAlignment', 'middle', ...
      'HorizontalAlignment', 'center', 'color', 'w', ...
      'Parent', handles.ax2PImage);
end

% - Configure axes for 2P image
axis(handles.ax2PImage, 'equal');
set(handles.ax2PImage, 'Color', [0 0 0], 'XTick', [], 'YTick', []);

% - Plot the receptive field for the selected ROIs
mfRFImage = MakeRFImage(hObject, handles, vnLabelRegions);
cla(handles.axRF);
imagesc(mfRFImage', 'Parent', handles.axRF);
axis(handles.axRF, 'equal', 'ij');
set(handles.axRF, 'Color', [0 0 0], 'XTick', [], 'YTick', []);

% - Plot the averaged response traces for the selected ROIs
vfAvgRegionResponse = nanmean(handles.mfRegionTraces(vnLabelRegions, :), 1);
cla(handles.axROIResponse);

vtStimDurations = handles.fsStack.vtStimulusDurations;
vtStimulusBlockStartTimes = cumsum([0; vtStimDurations]);

for (nStim = 1:size(handles.mfStimMeanResponses, 2))
   vfAvgStimTrace = [];
   vnNorm = [];
   for (nBlock = 1:numel(handles.fsStack.cstrFilenames))
      % - Find frames corresponding to this stimulus ID in this block
      vbStimBlockFrames = (handles.vnStimulusSeqID == nStim) & (handles.vnBlockIndex == nBlock);
      vfThisTrialTrace = vfAvgRegionResponse(vbStimBlockFrames);
      
      % - Find times to plot this response trace on
      vtThisPresTimes = vtStimulusBlockStartTimes(nStim) + handles.vtTimeInStimPresentation(vbStimBlockFrames);
      
      if (any(isnan(vfThisTrialTrace)))
         disp('bluh!');
      end
      
      % - Plot this trial trace
      plot(handles.axROIResponse, vtThisPresTimes, vfThisTrialTrace, 'Color', 0.25 * [1 1 1], 'LineWidth', 2);
      hold(handles.axROIResponse, 'on');
      
      % - Accumulate stim traces
      nStimLength = numel(vfThisTrialTrace);
      if (nStimLength > numel(vfAvgStimTrace))
         vfAvgStimTrace(nStimLength) = 0; %#ok<AGROW>
         vnNorm(nStimLength) = 0; %#ok<AGROW>
      end
      
      vfAvgStimTrace(1:nStimLength) = vfAvgStimTrace(1:nStimLength) + vfThisTrialTrace(1:nStimLength);
      vnNorm(1:nStimLength) = vnNorm(1:nStimLength) + 1;
   end
   
   if (any(isnan(vfAvgStimTrace ./ vnNorm)))
      disp('bluh!');
   end
   
   % - Plot the average fluorescence trace for the region
   nStimLength = numel(vfAvgStimTrace);
   vtThisStimTime = vtStimulusBlockStartTimes(nStim) + ((0:nStimLength-1)+0.5) * handles.fsStack.tFrameDuration;
   plot(handles.axROIResponse, vtThisStimTime, vfAvgStimTrace ./ vnNorm, 'r-', 'LineWidth', 1);
end

xlabel(handles.axROIResponse, 'Time (s)');
ylabel(handles.axROIResponse, 'ROI Response (dF/F%)');
axis(handles.axROIResponse, 'tight');

   
function tfOverviewImage = MakeOverviewImage(fsData)

% - Get average frames
strOldNorm = fsData.BlankNormalisation('none');
tfAvgSignal = fsData.SummedAlignedFrames(:, :, :, :);
vnStackSize = size(fsData, 1:2);
fsData.BlankNormalisation(strOldNorm);

% - Make an image
tfOverviewImage = tfAvgSignal;

if (size(fsData, 4) == 1)
   tfAvgSignal(:, :, 2) = 0;
end

% - Transpose image and normalise
tfOverviewImage(:, :, 1) = tfAvgSignal(:, :, 2)' - min(min(tfAvgSignal(:, :, 2)));
tfOverviewImage(:, :, 1) = tfOverviewImage(:, :, 1) ./ max(max(tfOverviewImage(:, :, 1)));
tfOverviewImage(:, :, 2) = tfAvgSignal(:, :, 1)' - min(min(tfAvgSignal(:, :, 1)));
tfOverviewImage(:, :, 2) = tfOverviewImage(:, :, 2) ./ max(max(tfOverviewImage(:, :, 2)));
tfOverviewImage(:, :, 3) = 0;


function mfRFImage = MakeRFImage(hObject, handles, vnSelectedROIs)

DEF_nRFSamplesPerDeg = 4;

% - Make a mesh
if (~isfield(handles, 'mfXMesh'))
   vfX = 0:(1/DEF_nRFSamplesPerDeg):handles.vfScreenSizeDeg(1);
   vfY = 0:(1/DEF_nRFSamplesPerDeg):handles.vfScreenSizeDeg(2);
   [handles.mfXMesh, handles.mfYMesh] = ndgrid(vfX, vfY);
end

% - Work out stimulus locations
if (~isfield(handles, 'tfGaussian'))
   vfStimSizeDeg = handles.fPixelSizeDeg .* handles.vnNumPixels * (1-handles.fPixelOverlap);
   vfXCentres = linspace(-vfStimSizeDeg(1)/2, vfStimSizeDeg(1)/2, handles.vnNumPixels(1) + 1) + (handles.fPixelSizeDeg * (1-handles.fPixelOverlap))/2;
   vfXCentres = vfXCentres(1:end-1);
   vfYCentres = linspace(-vfStimSizeDeg(2)/2, vfStimSizeDeg(2)/2, handles.vnNumPixels(2) + 1) + (handles.fPixelSizeDeg * (1-handles.fPixelOverlap))/2;
   vfYCentres = vfYCentres(1:end-1);
   
   vfXStimCentres = vfXCentres + handles.vfScreenSizeDeg(1)/2;
   vfYStimCentres = vfYCentres + handles.vfScreenSizeDeg(2)/2;
   
   [handles.mfXStimCentreMesh, handles.mfYStimCentreMesh] = meshgrid(vfXStimCentres, vfYStimCentres);
   
   % - Pre-compute distance meshes and unitary Gaussians
   for (nStimID = prod(handles.vnNumPixels):-1:1)
      tfDistanceMeshSqr(:, :, nStimID) = (handles.mfXMesh - handles.mfXStimCentreMesh(nStimID)).^2 + (handles.mfYMesh - handles.mfYStimCentreMesh(nStimID)).^2; %#ok<AGROW>
   end
   handles.tfGaussian = 1/(2*pi*(handles.fPixelSizeDeg/4).^2) .* exp(-1/(2*(handles.fPixelSizeDeg).^2) .* tfDistanceMeshSqr);
end

% - Iterate over ROIs and build up a Gaussian RF estimate
mfRFImage = zeros(size(handles.mfXMesh));

for (nROI = vnSelectedROIs)
   % - Accumulate Gaussians over stimulus locations for this RF
   if (handles.tBlankStimTime ~= 0)
      vfROIResponse = handles.mfStimMeanResponses(nROI, 2:end);
   else
      vfROIResponse = handles.mfStimMeanResponses(nROI, :);
   end
   vfROIResponse = permute(vfROIResponse, [3 1 2]);
   
   mfRFImage = mfRFImage + sum(bsxfun(@times, handles.tfGaussian, vfROIResponse), 3);
end

% - Store object data
guidata(hObject, handles);


%% -- Callback functions

% --- Executes on selection change in lbROIList.
function lbROIList_Callback(hObject, eventdata, handles)
% hObject    handle to lbROIList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = get(hObject,'String') returns lbROIList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lbROIList

% - Disable callback and object
set(hObject, 'Enable', 'off');

vfPosition = get(handles.figRFExplorer, 'Position');
vfPosition(1:2) = 0;

hBlankerAxes = axes('Units', get(handles.figRFExplorer, 'Units'), ...
                    'Position', vfPosition, 'Color', 'none', ...
                    'XTick', [], 'YTick', []);
hPatch = patch([0 0 1 1 0], [0 1 1 0 0], [.5 .5 .5]);
alpha(0.5);
drawnow;

% - Update figures
RFE_UpdateFigures(hObject, handles);

set(hObject, 'Enable', 'on');
delete(hBlankerAxes);

uicontrol(handles.lbROIList);


% --- Executes during object creation, after setting all properties.
function lbROIList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lbROIList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
   set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pbExportRF.
function pbExportRF_Callback(hObject, eventdata, handles)
% hObject    handle to pbExportRF (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% -- Create data for export

sExport.vnSelectedROIs = get(handles.lbROIList, 'Value');
sExport.mfRFImage = MakeRFImage(hObject, handles, sExport.vnSelectedROIs);
sExport.tfOverviewImage = handles.tfOverviewImage;
sExport.cstrFilenames = handles.fsStack.cstrFilenames;
sExport.sRegions = handles.sRegionsPlusNP;
sExport.sParams.vnNumPixels = handles.vnNumPixels;
sExport.sParams.fPixelOverlap = handles.fPixelOverlap;
sExport.sParams.fPixelSizeDeg = handles.fPixelSizeDeg;
sExport.sParams.vfScreenSizeDeg = handles.vfScreenSizeDeg;
sExport.sResponses.vtGlobalTime = handles.vtGlobalTime;
sExport.sResponses.vnBlockIndex = handles.vnBlockIndex;
sExport.sResponses.vnFrameInBlock = handles.vnFrameInBlock;
sExport.sResponses.vtTimeInBlock = handles.vtTimeInBlock;
sExport.sResponses.vnStimulusSeqID = handles.vnStimulusSeqID;
sExport.sResponses.vtTimeInStimPresentation = handles.vtTimeInStimPresentation;
sExport.sResponses.vnPresentationIndex = handles.vnPresentationIndex;
sExport.sResponses.vbUseFrame = handles.vbUseFrame;
sExport.sResponses.vfBlankStds = handles.vfBlankStds;
sExport.sResponses.mfStimMeanResponses = handles.mfStimMeanResponses;
sExport.sResponses.mfStimStds = handles.mfStimStds;
sExport.sResponses.mfRegionTraces = handles.mfRegionTraces;
sExport.sResponses.tfTrialResponses = handles.tfTrialResponses;
sExport.sResponses.tnTrialSampleSizes = handles.tnTrialSampleSizes;


% - Export RF structure
strVarname = sprintf('sRF%s', datestr(now, '_yyyymmdd_HHMM'));
assignin('base', strVarname, sExport);

fprintf(1, '--- RF_explorer: Receptive field exported to %s\n', strVarname);


