%This script combines and averages multiple anlyses of multiple mice
%run the PLR_analysis_individual script first 
%file per mouse
clear; clc; close all;

%% set parameters

run = 4; %run number to plot later
nThree = 1; %set to 1 for three conditions, 0 for 2 conditions

%%Load individually analyzed files for the first condition
ControlFiles = uipickfiles('FilterSpec','*.mat', 'Prompt','Load analyzed files for Condition 1 (Control)'); 
disp('Succesfully loaded ')
disp(ControlFiles)


%Load first file to get parameters and size array
%This depends on the fact that all were analyzed in the same way, which
%they should have been
%currently analyzing based on 5s average around lowest point of smoothened
%pupil trace
load(ControlFiles{1});
ExpRStar1 = ExpRStar;
combPupilTrace1 = zeros(TotalTime*SamplingRate-SafetyFactor, length(ExpRStar), length(ControlFiles));
combPupilChange1 = zeros(length(ExpRStar),length(ControlFiles));
combEC50_1 = zeros(length(ControlFiles),1);
combHill_1 = zeros(length(ControlFiles),1);
%load each PupilTrace into array
for i=1:length(ControlFiles)
    load(ControlFiles{i},'smoothPupil','PupilChangeLow','PupilTrace','EC50', 'Hill');
    
    combPupilTrace1(:,:,i) = smoothPupil(:,:);
    combPupilChange1(:,i) = PupilChangeLow;
   
    combEC50_1(i,1) = EC50;
    combHill_1(i,1) = Hill;
end

%Calculate mean and standard error
avgPupilChange1 = mean(combPupilChange1,2);
stdPupilChange1 = std(combPupilChange1,0,2);
SEMPupilChange1 = stdPupilChange1./sqrt(length(ControlFiles));

avgPupilTrace1 = mean(combPupilTrace1,3);
stdPupilTrace1 = zeros(length(avgPupilTrace1),length(ExpRStar),1);
stdPupilTrace1(:,:,1) = std(combPupilTrace1,0,3);
SEMPupilTrace1 = stdPupilTrace1./sqrt(length(ControlFiles));

avgEC50_1 = mean(log10(combEC50_1));
stdEC50_1 = std(log10(combEC50_1));
SEMEC50_1 = stdEC50_1./sqrt(length(ControlFiles));

avgHill_1 = mean(combHill_1);
stdHill_1 = std(combHill_1);
SEMHill_1 = stdHill_1./sqrt(length(ControlFiles));

%% Load individually analyzed files for the second condition
ExperimentFiles = uipickfiles('FilterSpec','*.mat', 'Prompt','Load analyzed files for Condition 2 (Experiment)'); 
disp('Succesfully loaded ')
disp(ExperimentFiles)

%Load first file to get parameters and size array
%This depends on the fact that all were analyzed in the same way, which
%they should have been
%Note that only the ones being considered together have to have the same
%parameters, these parameters do not have tomatch the first condition
load(ExperimentFiles{1});
ExpRStar2 = ExpRStar;

%Size array
combPupilChange2 = zeros(length(ExpRStar),length(ExperimentFiles));
combPupilTrace2 = zeros(TotalTime*SamplingRate-SafetyFactor, length(ExpRStar), length(ExperimentFiles));
combEC50_2 = zeros(length(ExperimentFiles),1);
combHill_2 = zeros(length(ExperimentFiles),1);
%load each PupilTrace into array
for i=1:length(ExperimentFiles)
    load(ExperimentFiles{i},'smoothPupil','PupilChangeLow','PupilTrace', 'EC50', 'Hill');
    %combPupilChange2(:,i) = PupilChange5;
    combPupilChange2(:,i) = PupilChangeLow;
    %combPupilChangeEnd2(:,i) = PupilChangeEnd;
    %combPupilTrace2(:,:,i) = PupilTrace(:,:);
    combPupilTrace2(:,:,i) = smoothPupil(:,:);
    combEC50_2(i,1) = EC50;
    combHill_2(i,1) = Hill;
end

%Calculate mean and standard error
avgPupilChange2 = mean(combPupilChange2,2,'omitnan');
stdPupilChange2 = std(combPupilChange2,0,2,'omitnan');
SEMPupilChange2 = stdPupilChange2./sqrt(length(ExperimentFiles));

avgPupilTrace2 = mean(combPupilTrace2,3,'omitnan');
stdPupilTrace2 = zeros(length(avgPupilTrace2),length(ExpRStar),1);
stdPupilTrace2(:,:,1) = std(combPupilTrace2,0,3,'omitnan');
SEMPupilTrace2 = stdPupilTrace2./sqrt(length(ExperimentFiles));

avgEC50_2 = mean(log10(combEC50_2),'omitnan');
stdEC50_2 = std(log10(combEC50_2),'omitnan');
SEMEC50_2 = stdEC50_2./sqrt(length(ExperimentFiles));

avgHill_2 = mean(combHill_2,'omitnan');
stdHill_2 = std(combHill_2,'omitnan');
SEMHill_2 = stdHill_2./sqrt(length(ExperimentFiles));



%% Load individually analyzed files for the second condition
if nThree == 1
ExperimentFiles2 = uipickfiles('FilterSpec','*.mat', 'Prompt','Load analyzed files for Condition 2 (Experiment)'); 
disp('Succesfully loaded ')
disp(ExperimentFiles2)

%Load first file to get parameters and size array
%This depends on the fact that all were analyzed in the same way, which
%they should have been
%Note that only the ones being considered together have to have the same
%parameters, these parameters do not have tomatch the first condition
load(ExperimentFiles2{1});
ExpRStar3 = ExpRStar;

%Size array
combPupilChange3 = zeros(length(ExpRStar),length(ExperimentFiles2));
combPupilTrace3 = zeros(TotalTime*SamplingRate-SafetyFactor, length(ExpRStar), length(ExperimentFiles2));
combEC50_3 = zeros(length(ExperimentFiles2),1);
combHill_3 = zeros(length(ExperimentFiles2),1);
%load each PupilTrace into array
for i=1:length(ExperimentFiles2)
    load(ExperimentFiles2{i},'smoothPupil','PupilChangeLow','PupilTrace','EC50', 'Hill');
    combPupilChange3(:,i) = PupilChangeLow;
    combPupilTrace3(:,:,i) = smoothPupil(:,:);
    combEC50_3(i,1) = EC50;
    combHill_3(i,1) = Hill;
end

%Calculate mean and standard error
avgPupilChange3 = mean(combPupilChange3,2);
stdPupilChange3 = std(combPupilChange3,0,2);
SEMPupilChange3 = stdPupilChange3./sqrt(length(ExperimentFiles2));

avgPupilTrace3 = mean(combPupilTrace3,3);
stdPupilTrace3 = zeros(length(avgPupilTrace3),length(ExpRStar),1);
stdPupilTrace3(:,:,1) = std(combPupilTrace3,0,3);
SEMPupilTrace3 = stdPupilTrace3./sqrt(length(ExperimentFiles2));

avgEC50_3 = mean(log10(combEC50_3));
stdEC50_3 = std(log10(combEC50_3));
SEMEC50_3 = stdEC50_3./sqrt(length(ExperimentFiles2));

avgHill_3 = mean(combHill_3);
stdHill_3 = std(combHill_3);
SEMHill_3 = stdHill_3./sqrt(length(ExperimentFiles2));
end
%% towards analysis

%create model sigmoidal function; b(1) is minimum value, b(2) is maximum
%value, b(3) is EC50, b(4) is Hill slope
%note that EC50 is for x that is halfway between b(1) and b(2), so not
%necessarily 0.5
SigmoidFit = @(b,x)(b(1)+(b(2)-b(1))./(1+(b(3)./x).^b(4)));
%Initial guess for least squares regression
beta0 = [0,1,100,1];
%define lower and upper bounds. Importantly, maximum is constrained to be
%at 1, and minimum is constrained to be at 0.2. 
lb1 = [0.2,1,ExpRStar1(1)/10,-10];
ub1 = [0.2,1,10*ExpRStar1(end),0];
lb2 = [0.2,1,ExpRStar2(1)/10000,-100];
ub2 = [0.2,1,100*ExpRStar2(length(ExpRStar2)),100];
if nThree == 1
lb3 = [0.2,1,ExpRStar3(1),-100];
ub3 = [0.2,1,10*ExpRStar3(length(ExpRStar3)),100];
end
%Plot and Fit for avgPupilChange
subplot(2,3,[1,2,4,5])
points1 = semilogx(ExpRStar1,avgPupilChange1, 'ko');
points1.MarkerSize = 7;
points1.MarkerFaceColor = [0 0 0];
hold on
points2 = semilogx(ExpRStar2,avgPupilChange2, 'bo');
points2.MarkerSize = 7;
points2.MarkerFaceColor = [0 0 1];
hold on
if nThree == 1
points3 = semilogx(ExpRStar3,avgPupilChange3, 'mo');
points3.MarkerSize = 7;
points3.MarkerFaceColor = [1 0 1];
end
%Set axes properties
Pupax = gca;
Pupax.Box = 'off';
Pupax.YLabel.String = 'Relative Pupil Area';
Pupax.YLabel.FontSize = 12;
Pupax.YLim = [0 1.2];
Pupax.YTick = [0.0 0.2 0.4 0.6 0.8 1.0];
Pupax.XLim = [ExpRStar2(1)/10 ExpRStar2(length(ExpRStar2))*10];
Pupax.XTick = [10^0 10^1 10^2 10^3 10^4 10^5];
Pupax.XTickLabel = {'0', '1', '2', '3', '4', '5'};
Pupax.XLabel.String = 'log(Illuminance (R*))';
%Generate fits
FitavgPupilChange1 = lsqcurvefit(SigmoidFit,beta0,ExpRStar1,avgPupilChange1,lb1,ub1);
FitavgPupilChange2 = lsqcurvefit(SigmoidFit,beta0,ExpRStar2,avgPupilChange2,lb2,ub2);
if nThree == 1
FitavgPupilChange3 = lsqcurvefit(SigmoidFit,beta0,ExpRStar3,avgPupilChange3,lb3,ub3);
end
hold on
%Space and plot fits
logrange = logspace(log10(1/10), log10(1000000*10));
line1 = semilogx(logrange, SigmoidFit(FitavgPupilChange1,logrange));
line1.Color = 'k';
line1.LineWidth = 1;
line2 = semilogx(logrange, SigmoidFit(FitavgPupilChange2,logrange));
line2.Color = 'b';
line2.LineWidth = 1;
if nThree == 1
line3 = semilogx(logrange, SigmoidFit(FitavgPupilChange3,logrange));
line3.Color = 'm';
line3.LineWidth = 1;
end
%Plot reference at PupilChange = 1
maxref = refline(0,1);
maxref.Color = 'k';
maxref.LineWidth = 1;
maxref.LineStyle = '--';
minref = refline(0,0.2);
minref.Color = 'k';
minref.LineWidth = 1;
minref.LineStyle = '--';
%Plot error bars
error1 = errorbar(ExpRStar1,avgPupilChange1,SEMPupilChange1,'.k');
error2 = errorbar(ExpRStar2,avgPupilChange2,SEMPupilChange2,'.b');
if nThree == 1
error3 = errorbar(ExpRStar3,avgPupilChange3,SEMPupilChange3,'.m');
end

%plot the EC50
subplot(2,3,[3,6])
EC50point1 = plot(1,avgEC50_1,'ko');
EC50point1.MarkerSize = 7;
EC50point1.MarkerFaceColor = [0 0 0];
hold on
EC50point2 = plot(2,avgEC50_2,'bo');
EC50point2.MarkerSize = 7;
EC50point2.MarkerFaceColor = [0 0 1];
if nThree == 1
EC50point3 = plot(3,avgEC50_3,'mo');
EC50point3.MarkerSize = 7;
EC50point3.MarkerFaceColor = [1 0 1];
end


%Set axes properties
ECax = gca;
ECax.Box = 'off';
ECax.YLabel.String = 'EC50 (log Illuminance in R*)';
ECax.YLabel.FontSize = 12;
ECax.YLim = [log10(ExpRStar2(1)/10) log10(ExpRStar2(length(ExpRStar1))*100000)];
ECax.YTick = [0 1 2 3 4 5 6 7 8 9 10];
ECax.YTickLabel = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10'};
ECax.XLim = [0 3];
ECax.XTick = [1 2];
ECax.XTickLabel = {'Control','Experimental'};
%Plot error bars
EC50error1 = errorbar(1,avgEC50_1,SEMEC50_1,'.k');
EC50error2 = errorbar(2,avgEC50_2,SEMEC50_2,'.b');
if nThree == 1
EC50error3 = errorbar(3,avgEC50_3,SEMEC50_3,'.m');
ECax.XLim = [0 4];
ECax.XTickLabel = {'Control','Experimental 1','Experimental 2'};
end


%which run to plot

%Plot pupiltrace
figure
timeVec = linspace(1/SamplingRate,(TotalTime*SamplingRate-SafetyFactor)/SamplingRate,length(PupilTrace));
%timeVec = linspace(1/SamplingRate,35,4200);
shadePlot(timeVec,avgPupilTrace1(:,run),SEMPupilTrace1(:,run,1),[0 0 0]);
hold on
shadePlot(timeVec,avgPupilTrace2(:,run),SEMPupilTrace2(:,run,1),[0 0 1]);
if nThree == 1
    shadePlot(timeVec,avgPupilTrace3(:,run),SEMPupilTrace3(:,run,1),[1 0 1]);
end

Trax = gca;
Trax.Box = 'off';
Trax.YLabel.String = 'Relative Pupil Area';
Trax.YLabel.FontSize = 12;
Trax.YLim = [0 1.2];
Trax.YTick = [0.0 0.2 0.4 0.6 0.8 1.0];
Trax.XLim = [0 65];
Trax.XTick = [0 5 10 15 20 25 30 35 40 45 50 55 60 65];
Trax.XTickLabel = {'0', '5', '10', '15', '20', '25', '30','35', '40', '45', '50', '55', '60', '65'};
Trax.XLabel.String = 'Time (s)';
%add reference lines
maxref = refline(0,1);
maxref.Color = 'k';
maxref.LineWidth = 1;
maxref.LineStyle = '--';
minref = refline(0,0.2);
minref.Color = 'k';
minref.LineWidth = 1;
minref.LineStyle = '--';
stimref = patch([5 5 35 35], [0 1.2 1.2 0], 'green');
stimref.FaceAlpha = 0.25;
stimref.EdgeColor = 'none';

[savefilename, savepathname] = uiputfile('.mat','Save as');
save([savepathname savefilename])