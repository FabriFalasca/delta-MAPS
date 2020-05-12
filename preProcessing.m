function  preProcessing(startYear, endYear,netSize,netWindow)

%% Brief description
%  This function is used to preprocess Sea Surface Temperature data.
%  The data are embedded in a 2-D grid with size d1 x d2.
%  The data coverage is from January 1870 to January 2016.
%  The arguments of the function are:
%  
%  1) startYear : first year of our analysis
%                 (ex. startYear = x would mean that our analysis would
%                  start from January of the year x)
%  2) endYear   : last year of our analysis
%                 (ex. endYear = x would mean that our analysis would
%                  finish at December of the year x)
%  3) netSize   : how many years to construct a network
%  4) netWindow : how many years from a network to another 

%  the function preProcessing remove the seasonal cycle and the linear trend from the data.
%  The output will be n de-seasonalized and detrended time series maps
%  from startYear to endYear.
%  The number of outputs will depend on startYear,
%  endYear,netSize,netWindow.

% for example
% preProcessing(1960, 2015, 50, 2)
% will produce 4 different 2-D grid fields, correspondent to the periods:
% 1960 - 2009
% 1962 - 2011
% 1964 - 2013
% 1966 - 2015
% for every grid point there would be a time series without the seasonal cycle and wirthout the linear trend.
%
% IMPORTANT
% if we just want 1 output with the de-seasonalized and detrended time series
% from startYear to endYear just set
% netWindow = 0
% if the netWindow is set equal to zero
% it doesn't matter what is the value of netSize (it can be set as any number: 1, 2 ...)
% the function itself will compute the netSize as (endYear - startYear + 1)


% Importing data
ncid = netcdf.open('HadISST_sst_remapBILINEAR_noHighLats.nc','NC_NOWRITE');
tos = double(netcdf.getVar(ncid,5)); % tos is the SST data
netcdf.close(ncid);

% Dimensions of the matrix
% we reverse the matrix to be able to plot it with pcolor
dimX = size(tos,2);
dimY = size(tos,1);
dimT = size(tos,3);
newTos = zeros(dimX,dimY,dimT);
for i = 1:dimT
    newTos(:,:,i) = tos(:,:,i)';
end;
% mask value (value for the land)
mask = min(min(min(tos(:,:,1))));
ind = find(newTos==mask);
% our mask
myMask = -1000000;
newTos(ind) = myMask;

%keep years from startyear to end Year
%note that the starting year in the data is 1870 (if we use HadSST)
newTos = keepGoodYears(newTos,1870,startYear,endYear);

% mask the poles
% we mask it because, this particular data take into consideration
% ice coverage.
% So we can end up to have masked values in time series in the poles
% just because of ice coverage.
% This is not good for our purposes
%{
for i = 1:dimY
    for z = 1:dimT
        for j = 1:30
            newTos(j,i,z) = myMask;
        end;
        for j = 151:180
            newTos(j,i,z) = myMask;
        end;
    end;
end;
%}

% In this particular data set, South America and Central America are
% not joined.
% This could result in a problem in the domain identification
% part of the Java code.
% We put a mask between Americas
for i = 1:dimT
    newTos(68,223,i) = myMask;
    newTos(68,224,i) = myMask;
    newTos(68,225,i) = myMask;
    newTos(68,226,i) = myMask;
end

% computing the number of networks
if( netWindow ~= 0) 
    nNetworks = floor(((endYear - startYear + 1) - (netSize - netWindow)) / netWindow);
else
    nNetworks = 1;
    netSize = endYear - startYear + 1;
end

for i = 0:(nNetworks-1)
    % start year of the network
    start_net_Year = startYear + i*netWindow ;
    % end year of the network
    end_net_Year = start_net_Year + netSize - 1;
    display('period : ')
    disp([num2str(start_net_Year),'-',num2str(end_net_Year)]);
    mytosToDetrend=keepGoodYears(newTos,startYear,start_net_Year,end_net_Year);

    % remove bad grid values
    display('removing bad grid cells')
    % we want to be sure that there are no "bad grid cells" in the data set
	% if there are, we mask them
	
    indMax = find(mytosToDetrend > 40);
    indMin = find(mytosToDetrend < -10);
    mytosToDetrend(indMax) = myMask;
    mytosToDetrend(indMin) = myMask;
    
    
    dimT=size(mytosToDetrend,3);
    
    display('checking the mask')
    % be sure on the mask
    % If a time series is masked at a time t, we want to be sure it is always
    % masked
	for k = 1:dimX
    	for j = 1:dimY;
        	ts = mytosToDetrend(k,j,:);
            ts = ts(:);
            for z = 1:dimT
                if(ts(z) == myMask)
                    mytosToDetrend(k,j,:) = myMask;
                end;
           	end;
    	end;
	end;
    
    % remove seasonality

    display('removing the seasonality')
    
	for k = 1:dimX
    	for j = 1:dimY
        	if(mytosToDetrend(k,j,1)~=myMask)
            	mytosToDetrend(k,j,:) = removeSeasonality(mytosToDetrend(k,j,:));
            end;
     	end;
	end;
    
    display('detrending the data')
   
	x=1:dimT;
	slopeMap = zeros(dimX,dimY);
	tosRegress = zeros(dimX,dimY,dimT);

    for k = 1:dimX
        for j = 1:dimY;
            ts = mytosToDetrend(k,j,:);
            ts = ts(:);
            if(ts(1)~= myMask)
                tosRegress(k,j,:)=detrend(ts);
                % to have informations on the slope of the line used to
                % detrend
                p = polyfit(x',ts,1);
                slope=p(1);
                slopeMap(k,j) = slope; 
            else
                tosRegress(k,j,:) = myMask;
            end;
        end;
    end;

    ind_seasonal=find(tosRegress==0);
    mytosToDetrend(ind_seasonal)=myMask;
    
	%%plot the std map;
	% Plotting the standard deviations map is useful to understand if
	% something went wrong in the preprocessing: if there are very
	% anomalous values something went wrong.

    
    display('computing the standard deviations')    
	stdmap = zeros(dimX,dimY);
	for x = 1:dimX
    	for y = 1:dimY
        	stdmap(x,y) = std(tosRegress(x,y,:));
    	end;
	end;
	figure(); 
	imagesc(stdmap); 
	title([num2str(start_net_Year),'-',num2str(end_net_Year)]); 
	colorbar;
    
	display('saving the outputs')
	filename = strcat('HadISST_sst_',num2str(start_net_Year),'_',num2str(end_net_Year));
	save(filename,'tosRegress');
    
   	filename = strcat('SLOPE_HadSST',num2str(start_net_Year),'_',num2str(end_net_Year));
	save(filename,'slopeMap');

end

% end of the function preProcessing
end




%% function used to remove the seasonality
function ts =  removeSeasonality(ts)

ts = ts(:);
monthlyAverage = zeros(1,12);
dimT = length(ts);
nYears = dimT/12;
for i = 1:dimT
    month = mod(i,12);
    if(month == 0)
        monthlyAverage(12) = monthlyAverage(12)+ts(i);
    else
        monthlyAverage(month) = monthlyAverage(month)+ts(i);
    end;
end;
monthlyAverage = monthlyAverage./nYears;


for i = 1:dimT
    month = mod(i,12);
    if(month == 0)
        ts(i)= ts(i) - monthlyAverage(12);
    else
        ts(i) = ts(i) - monthlyAverage(month);
    end
end;
end

