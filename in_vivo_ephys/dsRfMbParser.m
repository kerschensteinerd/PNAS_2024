%% DEFINE PATHS TO DATA

clear; clc; close all;

if ispc
    Kilosort_dir = 'D:\ds_pred\sc_rec\ChATDTR\20230422_poly3\1-6mm\kilosort3';
    MatParamFile = 'D:\ds_pred\sc_rec\ChATDTR\20230422_poly3\1-6mm\SC_April22_1_6mm.mat';
    % MatParamFileMb = 'D:\ds_pred\sc_rec\ChATDTR\20230205_poly3\1-2mm\SC_Feb05_1_2mm_MB.mat';
elseif ismac
    Kilosort_dir = '/Volumes/pHD_DK2/ds_pred/sc_rec/ChATDTR/20230414_poly3/1-2mm/kilosort3';
    MatParamFile = '/Volumes/pHD_DK2/ds_pred/sc_rec/ChATDTR/20230414_poly3/1-2mm/SC_April14_1_2mm.mat';
    % MatParamFileMb = '/Volumes/pHD_DK2/ds_pred/sc_rec/Control/20230310_poly3/1-1mm/SC_Feb05_1_2mm_MB.mat';
end


%% USER-DEFINED PARAMETERS

samp_freq = 30000;
binSize = 0.1; %in seconds
mbStimDur = 2.25; %in seconds


%% LOAD FILES

cd(Kilosort_dir)
spike_clusters = readNPY('spike_clusters.npy');
spike_times_raw= readNPY('spike_times.npy');
KSLabels = tdfread('cluster_KSLabel.tsv');
channel_positions = readNPY('channel_positions.npy');
templates = readNPY('templates.npy');
MatParams = load(MatParamFile);
% MatParamsMb = load(MatParamFileMb);


%% Get Xdat files for analog channel information

[fileName, pathName] = uigetfile('.json', 'Load Recorded File');
split_fileName = strsplit(fileName,'.');
datasource = split_fileName{1};
cd(pathName)
reader = allegoXDatFileReader;
timeRange = reader.getAllegoXDatTimeRange(datasource);

ADSave = [split_fileName{1} '_ADImport'];
if isfile([ADSave '.mat'])
    disp('Loading A/D Signals')
    load([ADSave '.mat'])
else
    disp('Loading Aux Signals')
    AuxStruct = reader.getAllegoXDatAuxSigs(datasource);
    VisStim = AuxStruct.signals(1,:);
    timeSamples = AuxStruct.timeSamples;
    timeStamps = AuxStruct.timeStamps;
    clear AuxStruct
    disp('Loading Digital Signals')
    DinStruct = reader.getAllegoXDatDinSigs(datasource);
    DinTrig = DinStruct.signals(1,:);
    clear DinStruct
    disp('Saving AD Values')
    save([pathName ADSave],'timeSamples','timeStamps','VisStim','DinTrig');
end

stimOnIdx = find(diff(round(VisStim/5))==1); %finds beginning of stimuli most accurately
stimOns = stimOnIdx./samp_freq; %adjust to s


%% PARSE SPIKE TIMES AND WAVEFORMS OF UNITS

unit = struct;
unitCount = 1;
spike_times = double(spike_times_raw);
rateTime = timeSamples(1):binSize:timeSamples(end);

for i = 1:length(KSLabels.cluster_id)
    unit(i).label = KSLabels.KSLabel(i,:);
    currSpikesIdx = find(spike_clusters==(i-1));
    currSpikes = spike_times(currSpikesIdx);
    currSpikes = double(currSpikes)./samp_freq;%convert to s
    unit(i).spikes = currSpikes;

    currTemplates = squeeze(templates(i,:,:));
    [~, t_ind] = min(currTemplates,[],'all','linear');
    [~, currChNo] = ind2sub(size(currTemplates),t_ind);
    unit(i).chanNum = currChNo;

    unit(i).chanDepth = channel_positions(currChNo,:);

    currWaveform = currTemplates(:,currChNo);
    unit(i).wave = currWaveform;

    [~,minIdx] = min(currWaveform);
    [~,widthIdx] = max(currWaveform(minIdx:end));
    currWidth = widthIdx/30; %30KHz. gives answer in ms
    unit(i).waveWidth = currWidth;

    [currRate,~] = histcounts(currSpikes,rateTime);
    unit(i).rate = currRate / binSize;
end


%% PARSE DRIFTING GRATING RESPONSES

stimDs = MatParams.DS_Data;
dsSpeed = double(MatParams.stimIn.Speed);
nDsSpeeds = length(dsSpeed);

dsDirection = double(MatParams.stimIn.Dir);
nDsDirections = length(dsDirection);

nDsRepeats = double(MatParams.stimIn.driftRepeats);

nDsStim = nDsRepeats*nDsDirections*nDsSpeeds;

stimDs(:,end+1) = zeros;
stimDs(2:end,end) = diff(stimDs(:,3));
stimDsStarts = zeros(nDsDirections,nDsSpeeds,nDsRepeats);
for i=1:nDsDirections
    for j=1:nDsSpeeds
        stimDsStarts(i,j,:) = stimDs(stimDs(:,4)==dsDirection(i) & stimDs(:,5)==dsSpeed(j) ...
            & stimDs(:,end)==1,1);
    end
end

dsStimOns = stimOns(end-nDsStim+1:end);
dsStimOnIdx = stimOnIdx(end-nDsStim+1:end);
newDsStimOns = dsStimOns;

%need to reconcile accurate start times of stimuli and inaccurate timing of
%order of stimuli presentation
[sortDsStarts,sortDsStarts_idx] = sort(stimDsStarts(:));
for s=1:nDsStim
    newDsStimOns(sortDsStarts_idx(s)) = dsStimOns(s);
end
newDsStimOns = reshape(newDsStimOns,nDsDirections,nDsSpeeds,nDsRepeats); %specific to order of the script

dsStimDur = double(MatParams.stimIn.driftDur);
dsStimInterDur = double(MatParams.stimIn.driftInterDur);

for i = 1:length(unit)
    currSpikes = unit(i).spikes;
    unit(i).dsSpikes = cell(nDsDirections,nDsSpeeds);
    unit(i).preDsSpikes = cell(nDsDirections,nDsSpeeds);
    unit(i).dsRepRel = zeros(nDsDirections,nDsSpeeds);
    for j = 1:nDsDirections
        for k = 1:nDsSpeeds
            for l = 1:nDsRepeats
                currOn = newDsStimOns(j,k,l);
                %spikes
                spIdx= find(currSpikes > currOn & currSpikes <= currOn + dsStimDur);
                currDsSpikes = currSpikes(spIdx)-currOn+dsStimInterDur; %#ok<FNDSB>
                if l==1
                    unit(i).dsSpikes{j,k} = currDsSpikes;
                else
                    unit(i).dsSpikes{j,k} = [unit(i).dsSpikes{j,k}; currDsSpikes + (l-1) * (dsStimDur+dsStimInterDur)];
                end
                stimRateTime = dsStimInterDur:binSize:dsStimInterDur+dsStimDur;
                [currDsRate,~] = histcounts(currDsSpikes,stimRateTime);
                unit(i).dsRate(j,k,l,:) = currDsRate / binSize;

                %pre spikes
                spIdx = find(currSpikes > currOn-dsStimInterDur & currSpikes <= currOn);
                currPreSpikes = currSpikes(spIdx)-currOn+dsStimInterDur;
                if l==1
                    unit(i).preDsSpikes{j,k} = currPreSpikes;
                else
                    unit(i).preDsSpikes{j,k} = [unit(i).preDsSpikes{j,k}; currPreSpikes + (l-1) * (dsStimDur+dsStimInterDur)];
                end
                preRateTime = 0:binSize:dsStimInterDur;
                [preDsRate,~] = histcounts(currPreSpikes,preRateTime);
                unit(i).preDsRate(j,k,l,:) = preDsRate / binSize;
            end
            %repeat reliability
            dsRateRepeats = squeeze(unit(i).dsRate(j,k,:,:));
            dsRepeatCorr = corrcoef(dsRateRepeats');
            dsRepeatCorrL = tril(dsRepeatCorr,-1);
            dsRepeatCorrLD = dsRepeatCorrL(:);
            dsRepeatCorrLD(dsRepeatCorrLD==0) = [];
            unit(i).dsRepRel(j,k) = mean(dsRepeatCorrLD,'omitnan');
        end
    end
end

%% PARSE MOVING BAR RESPONSES

stimMb = MatParams.MB_Data;
% stimMb = MatParamsMb.MB_Data;
mbSpeed = double(MatParams.stimIn.MB_Speed);
mbWidth = double(MatParams.stimIn.MB_Width);
nMbWidths = length(mbWidth);

mbDirection = double(MatParams.stimIn.MB_Dir);
nMbDirections = length(mbDirection);

nMbRepeats = double(MatParams.stimIn.MB_Repeats);

nMbStim = nMbDirections*nMbWidths*nMbRepeats;

stimMb(:,end+1) = zeros;
stimMb(2:end,end) = diff(stimMb(:,3));
stimMbStarts = zeros(nMbDirections,nMbWidths,nMbRepeats);
for i=1:nMbDirections
    for j=1:nMbWidths
        stimMbStarts(i,j,:) = stimMb(stimMb(:,4)==mbDirection(i) & stimMb(:,6)==mbWidth(j) ...
            & stimMb(:,end)==1,1);
    end
end

mbStimOns = stimOns(end-nDsStim-nMbStim+1:end-nDsStim);
mbStimOnIdx = stimOnIdx(end-nDsStim-nMbStim+1:end-nDsStim);
newMbStimOns = mbStimOns;

%need to reconcile accurate start times of stimuli and inaccurate timing of
%order of stimuli presentation
[sortMbStarts,sortMbStarts_idx] = sort(stimMbStarts(:));
for s=1:nMbStim
    newMbStimOns(sortMbStarts_idx(s)) = mbStimOns(s);
end
newMbStimOns = reshape(newMbStimOns,nMbDirections,nMbWidths,nMbRepeats); %specific to order of the script

mbStimInterDur = double(MatParams.stimIn.MB_InterDur);

for i = 1:length(unit)
    currSpikes = unit(i).spikes;
    unit(i).mbSpikes = cell(nMbDirections,nMbWidths);
    unit(i).preMbSpikes = cell(nMbDirections,nMbWidths);
    unit(i).mbRepRel = zeros(nMbDirections,nMbWidths);
    for j = 1:nMbDirections
        for k = 1:nMbWidths
            for l = 1:nMbRepeats
                currOn = newMbStimOns(j,k,l);
                %spikes
                spIdx= find(currSpikes > currOn & currSpikes <= currOn + dsStimDur);
                currMbSpikes = currSpikes(spIdx)-currOn+mbStimInterDur; %#ok<FNDSB> 
                if l==1
                    unit(i).mbSpikes{j,k} = currMbSpikes;
                else
                    unit(i).mbSpikes{j,k} = [unit(i).mbSpikes{j,k}; currMbSpikes + (l-1) * (mbStimDur+mbStimInterDur)];
                end
                stimRateTime = mbStimInterDur:binSize:mbStimInterDur+mbStimDur;
                [currMbRate,~] = histcounts(currMbSpikes,stimRateTime);
                unit(i).mbRate(j,k,l,:) = currMbRate / binSize;

                %pre spikes
                spIdx = find(currSpikes > currOn-mbStimInterDur & currSpikes <= currOn);
                currPreSpikes = currSpikes(spIdx)-currOn+mbStimInterDur;
                if l==1
                    unit(i).preMbSpikes{j,k} = currPreSpikes;
                else
                    unit(i).preMbSpikes{j,k} = [unit(i).preMbSpikes{j,k}; currPreSpikes + (l-1) * (mbStimDur+mbStimInterDur)];
                end
                preRateTime = 0:binSize:mbStimInterDur;
                [preMbRate,~] = histcounts(currPreSpikes,preRateTime);
                unit(i).preMbRate(j,k,l,:) = preMbRate / binSize;
            end
            %repeat reliability
            mbRateRepeats = squeeze(unit(i).mbRate(j,k,:,:));
            mbRepeatCorr = corrcoef(mbRateRepeats');
            mbRepeatCorrL = tril(mbRepeatCorr,-1);
            mbRepeatCorrLD = mbRepeatCorrL(:);
            mbRepeatCorrLD(mbRepeatCorrLD==0) = [];
            unit(i).mbRepRel(j,k) = mean(mbRepeatCorrLD,'omitnan');
        end
    end
end


%% MAP RECEPTIVE FIELDS

stimRf = MatParams.RF_Data;
azimuth = sort(unique(stimRf(:,4)));
nAzimuths = length(azimuth);
elevation = sort(unique(stimRf(:,5)));
nElevations = length(elevation);
nRfRepeats = double(MatParams.stimIn.spotRepeats);

nRfStim = nAzimuths*nElevations*nRfRepeats;

stimRf(:,end+1) = ones; %add column to stim matrix
stimRf(2:end,end) = diff(stimRf(:,3)); %identify transitions
stimRfStarts = zeros(nAzimuths,nElevations,nRfRepeats);

for i=1:nAzimuths
    for j=1:nElevations
        stimRfStarts(i,j,:) = stimRf(stimRf(:,4)==azimuth(i) & stimRf(:,5)==elevation(j) ...
            & stimRf(:,end)==1,1);
        %this looks through the stimulus file to identify the order of
        %stimuli presentation, and creates a matrix of onsets
    end
end

rfStimOns = stimOns(end-nDsStim-nMbStim-nRfStim+1:end-nDsStim-nMbStim);
rfStimOnIdx = stimOnIdx(end-nDsStim-nMbStim-nRfStim+1:end-nDsStim-nMbStim);
%stimOns = reshape(stimOns,nDir,nSpeed,nRepeats); %specific to order of the script
newRfStimOns = rfStimOns;

%need to reconcile accurate start times of stimuli and inaccurate timing of
%order of stimuli presentation
[sortRfStarts,sortRfStarts_idx] = sort(stimRfStarts(:));
for s=1:nRfStim
    newRfStimOns(sortRfStarts_idx(s)) = rfStimOns(s);
end
newRfStimOns = reshape(newRfStimOns,nAzimuths,nElevations,nRfRepeats); %specific to order of the script

onDur = double(MatParams.stimIn.spotDur);
offDur = double(MatParams.stimIn.spotInterDur);

for i = 1:length(unit)
    currSpikes = unit(i).spikes;
    unit(i).rfOnSpikes = cell(nAzimuths,nElevations);
    unit(i).rfOffSpikes = cell(nAzimuths,nElevations);
    for j = 1:nAzimuths
        for k = 1:nElevations
            for l = 1:nRfRepeats
                currOn = newRfStimOns(j,k,l);
                %ON and OFF spikes
                onSpIdx= find(currSpikes > currOn & currSpikes <= currOn + onDur);
                currOnSpikes = currSpikes(onSpIdx)-currOn;
                offSpIdx = find(currSpikes > currOn + onDur & currSpikes <= currOn + onDur + offDur);
                currOffSpikes = currSpikes(offSpIdx)-currOn;
                if l==1
                    unit(i).rfOnSpikes{j,k} = currOnSpikes;
                    unit(i).rfOffSpikes{j,k} = currOffSpikes;
                else
                    unit(i).rfOnSpikes{j,k} = [unit(i).rfOnSpikes{j,k}; currOnSpikes + (l-1) * (onDur + offDur)];
                    unit(i).rfOffSpikes{j,k} = [unit(i).rfOffSpikes{j,k}; currOffSpikes + (l-1) * (onDur + offDur)];
                end
                onRateTime = 0:binSize:onDur;
                [currOnRate,~] = histcounts(currOnSpikes,onRateTime);
                unit(i).onRate(j,k,l,:) = currOnRate / binSize;
                offRateTime = onDur:binSize:(onDur+offDur);
                [currOffRate,~] = histcounts(currOffSpikes,offRateTime);
                unit(i).offRate(j,k,l,:) = currOffRate / binSize;
            end
        end
    end
end


%% SAVE RESULTS

save([pathName split_fileName{1} '_parsed.mat'],'unit','MatParams')

