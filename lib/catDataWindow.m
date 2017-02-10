function cattedData = catDataWindow(dataTimes,data,eventTimes,window)
% CATDATAWINDOW concatenates windows of data, given event times and window
% around event times ([start stop] relative to event time)

% get sample rate
sampperiod = mode(diff(dataTimes));

% extract relevant times
numEvents = length(eventTimes);
cattedData = [];
for i = 1:numEvents
    tmp = data(dataTimes>=roundTime(eventTimes(i)+window(1),sampperiod) & dataTimes<roundTime(eventTimes(i)+window(2),sampperiod));
    cattedData = [cattedData; tmp];
end
