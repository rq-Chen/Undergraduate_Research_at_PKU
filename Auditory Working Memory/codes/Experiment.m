%    Modified by Hershey, 2019.11.2
%    L66 for forward setup
% 
%    Modified by Hershey, 2019.11.1
%    L308-326 : calculate the hitrate of each block and print it out
%   
% 
%
%   Modified by Hershey, 2019.10.1
%  L96-97 turn countSame&countDiff to vectors
%
%   Modified by Hershey, 2019.9.29
%  L38-39: alternative background color and text size
%  L28, L161-L207: Added an alternative for a Chinese version of introduction
%  L78: enlarge available number of subjects 
%  L272-276: rest for any length 
%  L299: save 'Subinfo'
%  notes for the beginning of the main trials and the end of each break
%    
%   Modified  by Ruiqi Chen, 2019.9.29
% 
% L154: countblock is defined as a scalar
% L152: IMPORTANT! (" - 1")
% L208: allow subjects to take a rest after every block; L218/225 added;
% L238: save data; L209/L214: string format
%
%	Conditions
%
% SIMPLE: simple comparison
% REVERSED: requiring subjects to mentally reverse S1 during retention,
%   then compare it with S2
% TRANSPOSITION: requiring subjects to mentally raise S1 for an octave
%   during retention, then compare it with S2
% CONTOUR: requiring subjects to mentally change the movement S1 into
%   categories ("up-up" / "up-down" / "down-up" / "down-down") during retention,
%   and that of S2 during reaction, then compare them


%parameters preparation
%--------------Language--------------%
isEnglish         = 0;  %1: English verion of introduction; 0: Chinese one
WINID = 2;  % 2 for the left and 1 for the right

%--------------color--------------%
BLACK             = [0 0 0];
WHITE             = [255 255 255];
GREY              = [128 128 128];
bgcolor           = GREY;
textsize          = 40;
%--------------blocks--------------%
NBLOCKS               = 8;                   % number of blocks
NTRIALS           = 54;                  % number of trials in a block
latincondition    = [1 3 2 4 2 1 4 3 1 3 2 4 2 1 4 3];    % latin square

%--------------sound--------------%
SAMPRATE          = 48000;               % you may need to change it to suit your audio device

%--------------response--------------%

TrialType         = zeros(NBLOCKS , NTRIALS);  % 1: different; 2: same
ResponseType      = TrialType;  % 0: no response; 1: different; 2: same
RT                = ResponseType;
hitrate           = zeros(4 , NTRIALS * 2);
% ramplen = [fix(samplerate * fade_duration), fix(samplerate * fade_duration)];
% outsig = rampsignal(a,ramplen);                        %调用rampsignal函数淡入淡出
isRepBlock = zeros(4,1);


%%
%信息录入
promptParameters = {'Subject Name','number'};
defaultParameters = {'sub99','99'}; %缺省值
Subinfo = inputdlg(promptParameters, 'Subject Info  ', 1, defaultParameters);

%%
try
    %窗口初始化
    HideCursor;%隐藏鼠标
    InitializePsychSound; %初始化PsychSound
    KbName('UnifyKeyNames');%键盘准备
    Screen('Preference', 'SkipSyncTests',1);%跳过硬件检测
    [w,dect]=Screen('OpenWindow',WINID,bgcolor);%打开一个窗口，灰色，全屏，返回句柄w和窗口向量rec
    cx=dect(3)/2;%获得中心点横坐标
    cy=dect(4)/2;%获得中心点纵坐标
    ListenChar(2);
    %flipint=Screen('GetFlipInterval',w);%获取刷新频率
    %pix = deg2pix(1,monitorsize,rec(3),subjdistance); %视角转pix
    keyend            = KbName('ESCAPE');
    keyspace          = KbName('SPACE');
    keyj              = KbName('J');
    keyk              = KbName('K');
    
    
    %-----------------------试次随机-----------------------%
    iblock            = mod(str2num(Subinfo{2})-1 , 8)+1;  %拉丁方的初始位置
    TrialType         = randtrial();  % 1: same; 0: different
    countblock        = 1; %记录block数目，用于休息以及标记使用过的声音
    
    %-------重要-------%
    %每名被试在实验开始前，都将声音文件进行随机化
    %并将正式实验用的声音序列分成两个，保证没有重复
    
    countDiff = ones(4,1); %标记变量初始化
    countSame = ones(4,1);
    PraCountDiff = 1;
    PraCountSame = 1;
    PracIndex = [randperm(27) ; randperm(27)];
    MainIndex = [randperm(54) ; randperm(54)];
    save Material.mat PraCountDiff PraCountSame countSame countDiff PracIndex MainIndex
    
    %-----------------%
    
    %%
    %----------------------呈现指导语----------------------%
    
    % Window
    %-----Attention for TextSize-----%
    % Screen('TextSize', w, textsize);
    % Screen('TextFont', w, 'Microsoft YaHei');
    Screen('TextColor', w, WHITE);
    HideCursor(w);
    
    % Welcome
    DrawFormattedText(w, 'Welcome', 'Center', 'Center');
    Screen('Flip', w);
    WaitSecs(2);
    
    %Introduction
    PROMPTS = cell(1, 6);
    if isEnglish
    PROMPTS{1, 1} = ['Simple Task\n    In every trial, you will hear a sequence ', ...
        'of three musical tones. Please keep it in your mind for 2 seconds. ', ...
        'Then you will hear another sequence and you need to compare it with ', ...
        'the one in your mind, and press J if they are the same, K ', ...
        'if different. You are allowed 2 seconds for reaction after ', ...
        'the offset of the second sequence. Then the next trial will begin ', ...
        'soon. During the whole trial, please fix at the cross at the center ', ...
        'of the screen, and try to avoid blinking or head movement.\n    Now ', ...
        'press space to continue, esc to quit.'];
    PROMPTS{1, 2} = ['Reversed Task\n    In every trial, you will hear a sequence ', ...
        'of three musical tones. Please reverse it in your mind in 2 seconds. ', ...
        'Then you will hear another sequence and you need to compare it with ', ...
        'the (reversed) one in your mind, and press J if they are the same, K ', ...
        'if different. You are allowed 2 seconds for reaction after ', ...
        'the offset of the second sequence. Then the next trial will begin ', ...
        'soon. During the whole trial, please fix at the cross at the center ', ...
        'of the screen, and try to avoid blinking or head movement.\n    Now ', ...
        'press space to continue, esc to quit.'];
    PROMPTS{1, 3} = ['Transposition Task\n    In every trial, you will hear a sequence ', ...
        'of three musical tones. Please raise the pitch for an octave in your mind in 2 seconds. ', ...
        'Then you will hear another sequence and you need to compare it with ', ...
        'the (raised) one in your mind, and press J if they are the same, K ', ...
        'if different. You are allowed 2 seconds for reaction after ', ...
        'the offset of the second sequence. Then the next trial will begin ', ...
        'soon. During the whole trial, please fix at the cross at the center ', ...
        'of the screen, and try to avoid blinking or head movement.\n    Now ', ...
        'press space to continue, esc to quit.'];
    PROMPTS{1, 4} = ['Contour Task\n    In every trial, you will hear a sequence ', ...
        'of three musical tones. Please mentally transform it in to categories ',...
        'up-up or up-down or down-up or down-down in 2 seconds, according to ', ...
        'the relative height of the tones. Then you will hear another sequence ', ...
        'and you should transform it likewise, then compare two result ', ...
        'and press J if they are the same, K ', ...
        'if different. You are allowed 2 seconds for reaction after ', ...
        'the offset of the second sequence. Then the next trial will begin ', ...
        'soon. During the whole trial, please fix at the cross at the center ', ...
        'of the screen, and try to avoid blinking or head movement.\n    Now ', ...
        'press space to continue, esc to quit.'];
    PROMPTS{1, 5} = ['first take a practice'];
    PROMPTS{1, 6} = ['ready for the main tasks?',...
        'if you got ready, press space for a start, or esc to quit', ];
    
    else 
        
        PROMPTS{1, 1, 1} = '简单任务    每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 1, 2} = '请将声音记在心中，保持2s ';
        PROMPTS{1, 1, 3} = '然后你会听到另一段声音，请把这段声音和之前记忆的声音进行比较 ';
        PROMPTS{1, 1, 4} = '如果相同，请按下"J"健，否则请按下"K"键 ';
        PROMPTS{1, 1, 5} = '声音播放完后，你有2s的时间进行按键反应 ';
        PROMPTS{1, 1, 6} = '然后下一个试次将很快开始 ';
        PROMPTS{1, 1, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点 ';
        PROMPTS{1, 1, 8} = '并尽量避免眨眼或者头动.按键之后可以眨眼     ';
        PROMPTS{1, 1, 9} = '如果准备好了，请按下空格键；如果想要退出，请按下esc键';
    
        PROMPTS{1, 2, 1} = '倒放任务     每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 2, 2} = '请将声音记在心中，并在2s之内将其倒序转换 ';
        PROMPTS{1, 2, 3} = '然后你会听到另一段声音，这段声音将原来的声音倒序播放';
        PROMPTS{1, 2, 4} = '请把这段声音和内心转换过的声音进行比较 ';
        PROMPTS{1, 2, 5} = '如果相同，请按下"J"健，否则请按下"K"键 ';
        PROMPTS{1, 2, 6} = '声音播放完后，你有2s的时间进行按键反应 ''然后下一个试次将很快开始 ';
        PROMPTS{1, 2, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点 ';
        PROMPTS{1, 2, 8} = '并尽量避免眨眼或者头动.按键之后可以眨眼';
        PROMPTS{1, 2, 9} = '如果准备好了，请按下空格键；如果想要退出，请按下esc键';
    
        PROMPTS{1, 3, 1} = '升调任务    每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 3, 2} = '请将声音记在心中，并在2s之内将其声调在心中升高一个八度 ';
        PROMPTS{1, 3, 3} = '然后你会听到另一段声音，这段声音将升高音调 ';
        PROMPTS{1, 3, 4} = '请把这段声音和内心转换过的声音进行比较 ';
        PROMPTS{1, 3, 5} = '如果相同，请按下"J"键，否则请按下"K"键 ';
        PROMPTS{1, 3, 6} = '声音播放完后，你有2s的时间进行按键反应, 然后下一个试次将很快开始 ';
        PROMPTS{1, 3, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点  ';
        PROMPTS{1, 3, 8} = '并尽量避免眨眼或者头动.按键之后可以眨眼     ';
        PROMPTS{1, 3, 9} = '如果准备好了，请按下空格键；如果想要退出，请按下esc键';

    
        PROMPTS{1, 4, 1} = '走向任务    每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 4, 2} = '请将声音记在心中，并按照三个音的相对音高，2s内在心中将它转化成下面四个种类中的一个： ';
        PROMPTS{1, 4, 3} = '（音调）"升高-升高" 或 "升高-降低" 或 "降低-升高" 或 "降低-降低"   ';
        PROMPTS{1, 4, 4} = '然后你会听到另一段声音，你需要进行同样的转换';
        PROMPTS{1, 4, 5} = '如果前后两段声音的种类相同，请按下"J"键，否则请按下"K"键 ';
        PROMPTS{1, 4, 6} = '声音播放完后，你有2s的时间进行按键反应, 然后下一个试次将很快开始';
        PROMPTS{1, 4, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点 ';
        PROMPTS{1, 4, 8} = '并尽量避免眨眼或者头动。按键之后可以眨眼';
        PROMPTS{1, 4, 9} = '如果准备好了，请按下空格键；如果想要退出，请按下esc键.';

    
    PROMPTS{1, 5} = '练习阶段';
    
    PROMPTS{1, 6} = '接下来是正式实验. 准备好后请按下空格键开始';
    
        
    end
    
    %%
    %----------------------正式实验----------------------%
    for iblock = iblock : iblock + NBLOCKS - 1
        condition = latincondition(iblock) ; %拉丁方条件
      
        
        %指导语
        if isEnglish
        DrawFormattedText(w, PROMPTS{1, condition}, fix(dect(3) / 8), fix(dect(4) / 8),...
            [], 70, [], [], 1.5);
        
        else
          drawTextAt(w,double(PROMPTS{1, condition, 1}), cx,cy-120 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 2}), cx,cy-90 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 3}), cx,cy-60 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 4}), cx,cy-30 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 5}), cx,cy    ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 6}), cx,cy+30 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 7}), cx,cy+60 ,[255 255 255]);  
          drawTextAt(w,double(PROMPTS{1, condition, 8}), cx,cy+90 ,[255 255 255]);
          drawTextAt(w,double(PROMPTS{1, condition, 9}), cx,cy+120 ,[255 255 255]);
        end
        
        Screen('Flip', w);
        
        %收集按键
        [~, ~,keyCode] = KbCheck;
        while ~(keyCode(keyend) || keyCode(keyspace))
            [~, ~,keyCode] = KbCheck;
        end
        if keyCode(keyend)
            sca; PsychPortAudio('Close');
            return;
        end
        
        
        %--------------------练习------------------%
        %指导语呈现2s
        if isEnglish
        DrawFormattedText(w, PROMPTS{1, 5}, fix(dect(3) / 8), fix(dect(4) / 8),...
            [], 70, [], [], 1.5);
        
        else
            
        drawTextAt(w,double(PROMPTS{1, 5}),cx,cy ,[255 255 255]); 
        end
        
        t = Screen('Flip', w);
        Screen('Flip', w,t+2);
        
        %呈现注视点，实验开始
        DrawFormattedText(w, '+', 'Center', 'Center', WHITE);
        Screen('Flip', w);
        
        AudioPlay(1 , condition);
        
        %--------------------正式------------------%
        %指导语
        Screen('FillRect', w , bgcolor);
        Screen('Flip', w);
        
        if isEnglish
        DrawFormattedText(w, PROMPTS{1, 6}, fix(dect(3) / 8), fix(dect(4) / 8),...
            [], 70, [], [], 1.5);
        else
        drawTextAt(w,double(PROMPTS{1, 6}),cx,cy ,[255 255 255]); 
        end
        
        Screen('Flip', w);
        
        %收集按键
        [~, ~,keyCode] = KbCheck;
        while ~(keyCode(keyend) || keyCode(keyspace))
            [~, ~, keyCode] = KbCheck;
        end
        if keyCode(keyend)
            sca; PsychPortAudio('Close');
            return;
        end
        
        sprintf('After practice, the Block %d begins', countblock)
        
        %呈现注视点，实验开始
        DrawFormattedText(w, '+', 'Center', 'Center', WHITE);
        Screen('Flip', w);
        
        
        %播放声音，收集按键
        [ResponseType(countblock , :) , RT(countblock , :)] = AudioPlay(0 , condition , TrialType(countblock , :));
        %
        
        %---------------------结果处理-------------------%
                
        sprintf('hitrate of this block')
        
        if ~isRepBlock(condition , 1) %如果这个条件是第一次出现
            hitrate(condition , 1:54) = ~(ResponseType(countblock , :) - TrialType(countblock , :));
        
            
            %打印击中率
            sum(hitrate(condition , 1 : 54 ) )./ 54
            
        else
            hitrate(condition , 55:108) = ~(ResponseType(countblock , :) - TrialType(countblock , :));
            
            %打印击中率
            sum(hitrate(condition , 55 : 108)) ./ 54
            
        end
            isRepBlock(condition , 1) = isRepBlock(condition , 1) + 1; 
            
        
        %---------------------休息-------------------%
        if countblock ~= 8 
            if isEnglish
            DrawFormattedText(w, 'take a rest for 2-3 min, press space to continue', fix(dect(3) / 8), fix(dect(4) / 8),...
                [], 70, [], [], 1.5);
            else
            drawTextAt(w,double('休息2-3min。如果想要继续，请按下空格键'),cx,cy ,[255 255 255]);
              
            end
            t = Screen('Flip', w);
            %收集按键
            [~, ~,keyCode] = KbCheck;
            while ~(keyCode(keyend) || keyCode(keyspace))
                [~, ~,keyCode] = KbCheck;
            end
            if keyCode(keyend)
                sca; PsychPortAudio('Close');
                return;
            end
            Screen('Flip', w); WaitSecs(0.5);
        end
        
        sprintf('Continue')
   
        countblock = countblock + 1 ;
        
    end
    
    
    %%
    %结果处理
    drawTextAt(w,double('实验结束'),cx,cy ,[255 255 255]);
    WaitSecs(2);
    Screen('CloseAll')
    ListenChar(0);
    
    %打印整个实验的击中率
    sum(hitrate, 2) ./ 108
    
    %保存被试信息、条件随机、反应&反应时
    save(sprintf('%s.mat', Subinfo{1}), 'Subinfo' , 'TrialType', 'ResponseType', 'RT', 'hitrate'); 
    save(sprintf('Material%s.mat', Subinfo{1}),'PracIndex', 'MainIndex', 'latincondition');
    
catch
    Screen('CloseAll')
    rethrow(lasterror)

    
end
%%

