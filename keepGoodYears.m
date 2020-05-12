function [ newdata ] = keepGoodYears( data,start,from,to )
%INPUT dataset with timeseries 
%OUTPUT same data set with trimmed time series keeping only the years of
%interest
%%how many years do you want?

newLength = (to-from+1)*12;
newdata = zeros(size(data,1),size(data,2),newLength);

%%find the position of the first january of the starting
%%year of interest
startPos = (from-start)*12+1;
% endPos = (to-start)*12+12-1; the -1 is added by Fabri the 15 of March
% 2016
%endPos = (to-start)*12+12-1;
endPos = (to-start)*12+12;
cc=1;
for i = startPos:endPos
    newdata(:,:,cc) = data(:,:,i);
    cc=cc+1;
end;

end

