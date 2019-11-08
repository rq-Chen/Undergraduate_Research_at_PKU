%% AudioPlayForTest.m - only for debugging (fewer trials)
%
% When you want to debug, change the filename to AudioPlay and change the
% original AudioPlay to some other name.
function[reaction , RT] = AudioPlay(isPractice , blocktype , trialtype  )

%New!本函数实现功能：完成一个block的播放声音，并传回被试的反应（按键序号即可）
%ispractice  2: main practice; 1：practice; 0：main experiment
%blocktype  1：simple、2：reversed、3：transposition、4：contour
%trialtype  正式实验时表示条件 1：same，2：different 长度为54的向量
%reaction  记录按键结果，长度为54的向量
%RT  记录反应时，长度为54的向量

% Modified by Hershey, 2019.9.29
% L63 & L71，newly defined PsychPortAudio('Start')
% L50, newly defined PsychPortAudio('Open')
% L111, not allow for escaping
% Trigger added
% every practice and block followed by a printed note

% Modified by Ruiqi Chen, 2019.9.29
%
% L4, L38, L48-49, L59, L67 (in this file); L34-36 moved; L32/39 for
% debugging; L117-125 modified

% Variables:
%
% Stilmuli: 4 (SIMPLE/REVERSED/TRANSPOSITION/CONTOUR) * 2 (SAME/DIFFERENT)
%   * 54 (NTRIAL) * 154350 (3.5 * SAMPRATE) double.
% PracticeStimuli: 4 * 2 * 27 * 154350 double, different from Stimuli
try

load('Material.mat') ;%加载音频文件,加载标记变量


KbName('UnifyKeyNames');        %键盘准备

SAMPRATE      = 48000;
PORTNUM = 53264;  % 53264 for the left room, 49408 for the right
reaction      = zeros(54, 1);
RT            = zeros(54, 1);
AudioInput    = zeros(2, 3.5 * SAMPRATE);

%%%%--------%%%%
numPractice   = 2;    %练习次数，2，一半same 一半different
%%%%--------%%%%
if isPractice == 2
    numPractice = numPractice * 3;
end

seqPractice   = randi(2 , 1, numPractice) ; %练习条件 1：different、2：same
%%%%--------%%%%
numMain       = 4;    %正式实验次数，4次每个block
%%%%--------%%%%
index         = 1;    %正式实验中声音序列随机index

%% 条件播放
% 先进行练习，再进行正式实验

pahandle=PsychPortAudio('Open',[],[],3,SAMPRATE);% 打开声音设备，默认播放设备，默认模式，延迟模式3，默认双声道

if isPractice    %练习条件下
    load('sti48000Pra.mat');
    PraCountDiff = mod(PraCountDiff - 1, 27) + 1;
    PraCountSame = mod(PraCountSame - 1, 27) + 1;  % from 1 to 27
    
    for itrial = 1 : numPractice
        WaitSecs(0.5 + rand(1) / 2);  % random ITI
        if seqPractice(itrial) == 1    %Different 条件
            index = PracIndex(1,PraCountDiff);
            AudioInput(1 , :) = PracticeStimuli(blocktype , 2 ,index , :) ;
            AudioInput(2 , :) = AudioInput(1 , :) ;
            PsychPortAudio('FillBuffer',pahandle , AudioInput);
            PsychPortAudio('Start',pahandle,[],[],1); %声音设备开启后再开始
            PraCountDiff = mod(PraCountDiff, 27) + 1;
            
        else                           %Same 条件
            index =  PracIndex(2,PraCountSame) ;
            AudioInput(1 , :) = PracticeStimuli(blocktype , 1 , index , :) ;
            AudioInput(2 , :) = AudioInput(1 , :) ;
            PsychPortAudio('FillBuffer',pahandle,AudioInput);
            PsychPortAudio('Start',pahandle,[],[],1); %声音设备开启后再开始
            PraCountSame = mod(PraCountSame, 27) + 1;
        end
        
        %收集按键, 限时2s，不记录结果，可以退出
        RTBegin = WaitSecs(2 + 6 * 0.25);
        RTTimeOut = RTBegin + 2;
        
        [secs, keyCode, ~] = KbWait([], 0, RTTimeOut);
        if find(keyCode) == KbName('ESCAPE')
            sca; PsychPortAudio('Close');
            return;
        end
        
        WaitSecs('UntilTime', RTTimeOut);
        
       
    end
     sprintf('Practice finished')
    
    
else    %正式实验
    load(['sti48000Block' num2str(blocktype) '.mat']);
    for itrial = 1 : numMain
        lptwrite(PORTNUM, 0);
        WaitSecs(0.5 + rand(1) / 2);  % random ITI
        
        if trialtype(itrial) == 1     %Different 条件
            index = MainIndex(1,countDiff(blocktype, 1)); 
            AudioInput(1 , :) = Stimuli(1 , 2 , index, : ) ;
            AudioInput(2 , :) = AudioInput(1 , :) ;
            PsychPortAudio('FillBuffer',pahandle,AudioInput);
            PsychPortAudio('Start',pahandle);
            %-------trigger------%
            lptwrite(PORTNUM, 1 + blocktype*10);
            % 49408 for the right room, 53264 for the left
            %--------------------%
            countDiff(blocktype, 1) = countDiff(blocktype, 1) + 1;
        else                           %Same 条件
            index = MainIndex(2,countSame(blocktype, 1));
            AudioInput(1 , :) = Stimuli(1 , 1 , index , : ) ;
            AudioInput(2 , :) = AudioInput(1 , :) ;
            PsychPortAudio('FillBuffer',pahandle,AudioInput);
            PsychPortAudio('Start',pahandle);
            %-------trigger------%
            lptwrite(PORTNUM, 2 + blocktype*10);      %trigger
            %--------------------%
            countSame(blocktype, 1) = countSame(blocktype, 1) + 1;
        end
        
        %收集按键, 限时2s，记录结果，不可退出
        RTBegin = WaitSecs(2 + 6 * 0.25);
        RTTimeOut = RTBegin + 2;
        
        [secs, keyCode, ~] = KbWait([], 0, RTTimeOut);
        
        if secs < RTTimeOut
            RT(itrial) = secs - RTBegin;
            if find(keyCode) == KbName('J')
                reaction(itrial) = 2;
            end
            if find(keyCode) == KbName('K')
                reaction(itrial) = 1;
            end
        end        
        
        WaitSecs('UntilTime', RTTimeOut);
        
    end
    sprintf('Blocktype %d finished', blocktype)
end
PsychPortAudio('Close',pahandle);

save Material.mat  PraCountDiff PraCountSame countSame countDiff PracIndex MainIndex


catch
    Screen('CloseAll')
    rethrow(lasterror)
    
    
end



