function [h,averageData,dataCIlow,dataCIhigh] = getPEH(dataTimes,data,eventTimes,window)

% extract relevant times
for i = 1:length(eventTimes)
    tmp = data(dataTimes>=roundTime(eventTimes(i)+window(1),0.0005) & dataTimes<roundTime(eventTimes(i)+window(2),0.0005))';
    dataWindow(i,:) = tmp;
end

h=0;
averageData = mean(dataWindow);
dataCIlow = 0;
dataCIhigh = 0;