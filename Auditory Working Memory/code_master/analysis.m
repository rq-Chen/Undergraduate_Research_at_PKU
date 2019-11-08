%% results analysis

%resultsRT:   condition(4) * trials(108)
%meanRT:      condition(4) * meanRT(1)
%resultsHT:   condition(4) * response(108, 1 for hit, 0 for miss)
%hitrate:     condition(4) * hitrate(%)

%%
resultsName   = ['subjectname.mat'];
materialName  = ['Materialsubjectname.mat'];

load(resultsName);
load(materialName);

resultsRT = zeros(4 , 108);
%% if hitrate analyzed

resultsHT = hitrate ;
hitrate   = sum(hitrate , 2) ./ 108;


%% hitrate analysis(if no hitrate record)
isRepBlock = zeros(4 , 1) ;
countblock        = 1;
iblock            = mod(str2num(Subinfo{2})-1 , 8)+1;  %拉丁方的初始位置

for iblock = iblock : iblock + 7
        if ~isRepBlock(condition , 1) %如果这个条件是第一次出现
            hitrate(condition , 1:54) = ~(ResponseType(countblock , :) - TrialType(countblock , :));
        
        
        else
            hitrate(condition , 55:108) = ~(ResponseType(countblock , :) - TrialType(countblock , :));
        end
            isRepBlock(condition , 1) = isRepBlock(condition , 1) + 1;
            countblock = countblock + 1;
end 

resultsHT = hitrate ;
hitrate   = sum(hitrate , 2) ./ 108;


%% RT analysis
isRepBlock = zeros(4 , 1) ;
countblock        = 1;
iblock            = mod(str2num(Subinfo{2})-1 , 8)+1;  %拉丁方的初始位置

for iblock = iblock : iblock + 7
    condition = latincondition(iblock);
    if ~isRepBlock
        resultsRT(condition , 1:54) = RT(countblock , :);
        
    else
        resultsRT(condition , 55:108) = RT(countblock , :);
    end
    countblock = countblock + 1;
    isRepBlock(condition , 1) = isRepBlock(condition , 1) + 1; 
end

meanRT = mean(resultsRT, 2);
