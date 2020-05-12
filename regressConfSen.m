function [ slopeMap, data_noTre ] = regressConfSen( dataset )


slopeMap = zeros(size(dataset,1),size(dataset,2));
for i = 1:size(slopeMap,1)
    for j = 1:size(slopeMap,2)
        slopeMap(i,j) = NaN;
    end;
end;
data_noTre = zeros(size(dataset,1),size(dataset,2),size(dataset,3));

for i = 1:size(dataset,1)
    for j = 1:size(dataset,2)
        cella = dataset(i,j,:); cella = cella(:);
        if(cella(1)~= -1000000)
            [resid,senSlope] = senEstimatorIlias(cella);
            slopeMap(i,j) = senSlope;
            data_noTre(i,j,:) = resid;
        else
            for z = 1:size(data_noTre,3)
                data_noTre(i,j,z) = -1000000;
            end;
        end;
    end;
end;


end

