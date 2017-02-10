function [averageData,dataCIlow,dataCIhigh] = getPEH(dataTimes,data,eventTimes,window)

% extract relevant times
numEvents = length(eventTimes);
for i = 1:numEvents
    tmp = data(dataTimes>=roundTime(eventTimes(i)+window(1),0.0005) & dataTimes<roundTime(eventTimes(i)+window(2),0.0005))';
    dataWindow(i,:) = tmp;
end

averageData = mean(dataWindow);

binned_stderr = std(dataWindow)/sqrt(numEvents); % standard error
tscore = tinv(0.975,numEvents-1); % t-score for 95% CI

dataCIlow = averageData - binned_stderr*tscore;
dataCIhigh = averageData + binned_stderr*tscore;