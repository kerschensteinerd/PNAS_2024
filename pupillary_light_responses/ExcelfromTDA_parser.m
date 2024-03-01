%The purpose of this script is to to parse a TDA file from the ISCAN
%software, which must already have been converted to an excel file.
%The script then allows you to select which parameter you care about, then
%normalizes the data, averages it across trials, and loads it into a matrix
%for future analysis

%% Clear and initialize
clear; clc; close all;

%Get path for excel files
ExcelFiles = uipickfiles('FilterSpec','*.xlsx', 'Prompt','Load Excel files for parsing'); 
disp('Succesfully found Excel Files')

%Get path for experimental parameters
ExpFiles = uipickfiles('FilterSpec','*.mat', 'Prompt','Load experimental parameters'); 
disp('Succesfully found Experimental Parameters')


if length(ExcelFiles) ~= length(ExpFiles)
    disp('ERROR: File Mismatch')
    return
end

%User input for desired parameter, use these variables later in code as
%desired for whatever measurement you want
prompt = {'Variable (1 = PupilHDiameter, 2 = PupilVDiameter, 3 = PupilArea)', 'Pixels in 1 mm?'};
title = 'Select desired parameter for trace'; nLines = 1;
defaultAnswer = {'3', '32'};
answer = inputdlg(prompt, title, nLines, defaultAnswer);
param = str2double(answer{1});
pixelpermm = str2double(answer{2});

%% Parse each file

for f = 1:length(ExcelFiles)
    

%Load entire Excel file
[num,txt,raw] = xlsread(ExcelFiles{f});
Xsplit = strsplit(ExcelFiles{f},'\');
fileName = char(Xsplit(length(Xsplit)));
disp(['Succesfully loaded ', fileName])

%Load experimental parameters
load(ExpFiles{f});
ExpPath = strsplit(ExpFiles{f},'\');
exppathName = strjoin(ExpPath(1:length(ExpPath)-1),'\');
expfileName = char(ExpPath(length(ExpPath)));
disp(['Succesfully loaded ', expfileName])

%User defined parameters
NumRuns = length(ExpRStar) * RunsPerStim;
TotalTime = stimLength + baseline + postStim;
SamplingRate = 120; %Default
%Select columns, they have to be sequential
BeginColumn = 10;
EndColumn = 12;
NumParameters = EndColumn-BeginColumn+1;
SafetyFactor = 12; %How much data you're willing to lose. ISCAN doesn't
%stop recording at eactly the right time, so some
%runs are longer and others are shorter. By setting this to 12, you're
%effectively making the run 0.1s shorter (12/120Hz) when you analyze it,
%since all runs should be at least that long.

%Correct for mistakes in ISCAN file (ie, unintended extra runs at
 %beginning)
 prompt = {'Errors? (yes or no)', 'Unintended extra runs at beginning?'};
 title = 'Denote any errors in ISCAN file'; nLines = 1;
 defaultAnswer = {'no', '0'};
 answer = inputdlg(prompt, title, nLines, defaultAnswer);
 if strcmp(answer{1},'no')
     fudge = 0;
 else
     fudge = str2double(answer{2});
 end

 NumRuns = NumRuns + fudge;

%Size collection for time and memory
ConvData = zeros(TotalTime*SamplingRate-SafetyFactor, NumParameters, NumRuns);

disp('Parsing data, this may take several moments')

%Begin parsing

%Filter any extraneous rows (when ISCAN cpu on for few days, starts to add 0 data)
ToDelTxt = [];
ToDelNum = [];
extra = 1;
for jj = 1:length(txt)
    %note extraneous points 
    if (strncmp(string(txt(jj,9)), string('   0x 00'),8) == 1)
        ToDelTxt(extra,1) = jj;
        ToDelNum(extra,1) = jj-5; %corrects for offset between txt and num due to header
        extra = extra + 1;
    end
end
%Filter Extraneous Points
if extra > 1
    txt(ToDelTxt,:) = [];
    num(ToDelNum,:) = [];
end


%Start by making a map of start times for each Run; run through file once,
%marking location of Run Headers
map = zeros(NumRuns,1);
key = 1;
for jj = 1:length(txt)
    if (strncmp(string(txt(jj,1)), string('Run  '),5) == 1)
        map(key,1) = jj-5; %corrects for offset between txt and num due to header
        key = key + 1;
    end
end

%Use Map to populate data
for ii = 1:NumRuns
    ConvData(:,:,ii) = num(map(ii,1):map(ii,1)+TotalTime*SamplingRate-SafetyFactor-1, BeginColumn:EndColumn);
end

%corect for fudge
for ii = 1:fudge
     ConvData(:,:,ii) = [];
end
NumRuns = NumRuns-fudge;

%Filter data to remove dropped points, if any
ConvData(ConvData == 0) = NaN;
%Normalize data; normalizes each trace to the baseline average of each
%trace; store baseline value so the original trace can be restored
normConvData = ConvData;
baselineAvg = zeros(length(ExpRStar)*RunsPerStim,1);
baselineAvgHDiameter = zeros(length(ExpRStar)*RunsPerStim,1);
baselineAvgVDiameter = zeros(length(ExpRStar)*RunsPerStim,1);
baselineAvgArea = zeros(length(ExpRStar)*RunsPerStim,1);
for jj = 1:length(ExpRStar)*RunsPerStim
    normConvData(:,param,jj) = ConvData(:,param,jj)/mean(ConvData(1:baseline*SamplingRate,param,jj), 1 , 'omitnan');
    baselineAvg(jj) = mean(ConvData(1:baseline*SamplingRate,param,jj), 1 , 'omitnan');
    baselineAvgHDiameter(jj) = mean(ConvData(1:baseline*SamplingRate,1,jj), 1 , 'omitnan');
    baselineAvgVDiameter(jj) = mean(ConvData(1:baseline*SamplingRate,2,jj), 1 , 'omitnan');
    baselineAvgArea(jj) = mean(ConvData(1:baseline*SamplingRate,3,jj), 1 , 'omitnan');
end

%Average runs together for each trial
%first size arraybasel
PupilTrace = zeros(length(ConvData), length(ExpRStar));
%Look through and average the trace for the desired parameter
for ii = 1:length(ExpRStar)
    PupilTrace(:,ii) = mean(normConvData(:,param,RunsPerStim*ii-RunsPerStim+1:RunsPerStim*ii),3, 'omitnan');
end

%save each file as go along
savepathName = [exppathName '\'];
fileless = strsplit(expfileName, '.mat');
savefileName = [char(fileless(1)) '_parsed.mat'];

disp(['Saving ' savefileName])

save([savepathName savefileName], 'AllCalib', 'baseline', 'baselineAvg', 'baselineAvgHDiameter', 'baselineAvgVDiameter', 'baselineAvgArea', 'darkIntensity','darkTime','ExpRStar', ...
    'FinalExpRStar','FinalIntCommands','indexNDF','NumRuns','param','PupilTrace', 'postStim', 'RunsPerStim',...
    'SafetyFactor','SamplingRate','stimLength','TotalTime', 'pixelpermm')
end

disp('The End')