function [averageData,dataCIlow,dataCIhigh,dataWindow] = getPEH(dataTimes,data,eventTimes,window)
% GETPEH Calculates peri-event histogram for data, given the data time
% vector, data, event times, and a window around the event (specified by an
% event-relative [start stop] window vector)

% get sample rate
sampperiod = mode(diff(dataTimes));

% extract relevant times
numEvents = length(eventTimes);
for i = 1:numEvents
    tmp = data(dataTimes>=roundTime(eventTimes(i)+window(1),sampperiod) & dataTimes<roundTime(eventTimes(i)+window(2),sampperiod))';
    dataWindow(i,:) = tmp;
end

averageData = mean(dataWindow);

binned_stderr = std(dataWindow)/sqrt(numEvents); % standard error
tscore = tinv(0.975,numEvents-1); % t-score for 95% CI

dataCIlow = averageData - binned_stderr*tscore;
dataCIhigh = averageData + binned_stderr*tscore;