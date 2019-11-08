function[trial] = randtrial()

%% introduction
%本函数实现以下功能：产生一个1/2随机数列，长度为54，1/2数目相同，最多只有2个连续相同
%方法：长度为54，故1和2各27个，将1个或2个连续作为一个单位，连续一个记为1，连续2个记为2
%生成两个序列，分别代表1或2的排列，并将该序列交替转换为目标的1/2序列

trial = ones(8 , 54);  % add 27 '2's to every block later


for iblock = 1 : 8   %共8个block
    seq0 = mod(randperm(18) , 2);  %生成0的随机数列
    seq1 = mod(randperm(18) , 2);  %生成1的随机数列
    itrial = 1;  %标记每个block的第几个trial
    for i = 1 : 18
        if seq0(i) == 0  %标记位置0
            itrial = itrial + 1;
        elseif seq0(i) == 1
            itrial = itrial + 2;
        end
        
        trial(iblock , itrial) = 2;  %标记位置2
        itrial = itrial +1;
        
        if seq1(i) == 1
            trial(iblock , itrial) = 2;
            itrial = itrial +1;
        end
        
    end
    
end
