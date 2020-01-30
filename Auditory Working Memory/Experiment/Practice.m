%此脚本实现集中练习
%次数为30次
%   Modified by Ruiqi Chen, 2019.9.29
%
% L133;

%parameters preparation

isEnglish         = 0;  %1: English verion of introduction; 0: Chinese one
WINID = 2;

%--------------color--------------%
BLACK             = [0 0 0];
WHITE             = [255 255 255];
GREY              = [128 128 128];
bgcolor           = GREY;
%--------------sound--------------%
SAMPRATE          = 48000;               % you may need to change it to suit your audio device

%%
try
    %窗口初始化
    HideCursor;%隐藏鼠标
    InitializePsychSound; %初始化PsychSound
    KbName('UnifyKeyNames');%键盘准备
    Screen('Preference', 'SkipSyncTests',1);%跳过硬件检测
    [w,dect]=Screen('OpenWindow',WINID,bgcolor);%打开一个窗口，全屏，返回句柄w和窗口向量rec
    cx=dect(3)/2;%获得中心点横坐标
    cy=dect(4)/2;%获得中心点纵坐标
    %ListenChar(2);
    %flipint=Screen('GetFlipInterval',w);%获取刷新频率
    %pix = deg2pix(1,monitorsize,rec(3),subjdistance); %视角转pix
    keyend            = KbName('ESCAPE');
    keyspace          = KbName('SPACE');
    keyj              = KbName('J');
    keyk              = KbName('K');  

    %-------重要-------%
    %每名被试在实验开始前，都将声音文件进行随机化
    %并将正式实  验用的声音序列分成两个，保证没有重复

    countDiff = 1; %标记变量初始化
    countSame = 1;
    PraCountDiff = 1;
    PraCountSame = 1;
    PracIndex = [randperm(27) ; randperm(27)];
    MainIndex = [randperm(54) ; randperm(54)];
    save Material.mat PraCountDiff PraCountSame countSame countDiff PracIndex MainIndex
       
    %-----------------%
    
    %%
    %----------------------呈现指导语----------------------%

% Window
% Screen('TextSize', w, 40);
% Screen('TextFont', w, 'Microsoft YaHei');
Screen('TextColor', w, WHITE);
HideCursor(w);

% Welcome
DrawFormattedText(w, 'Welcome for a practice', 'Center', 'Center');
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
        PROMPTS{1, 1, 9} = '如果准备好了，请按下空格键；如果有疑问,请向主试示意';
    
        PROMPTS{1, 2, 1} = '倒放任务     每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 2, 2} = '请将声音记在心中，并在2s之内将其倒序转换 ';
        PROMPTS{1, 2, 3} = '然后你会听到另一段声音，';
        PROMPTS{1, 2, 4} = '请把这段声音和内心转换过的声音进行比较 ';
        PROMPTS{1, 2, 5} = '如果相同，请按下"J"健，否则请按下"K"键 ';
        PROMPTS{1, 2, 6} = '声音播放完后，你有2s的时间进行按键反应 ''然后下一个试次将很快开始 ';
        PROMPTS{1, 2, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点 ';
        PROMPTS{1, 2, 8} = '并尽量避免眨眼或者头动.按键之后可以眨眼';
        PROMPTS{1, 2, 9} = '如果准备好了，请按下空格键；如果有疑问,请向主试示意';
    
        PROMPTS{1, 3, 1} = '升调任务    每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 3, 2} = '请将声音记在心中，并在2s之内将其声调在心中升高一个八度 ';
        PROMPTS{1, 3, 3} = '然后你会听到另一段声音，';
        PROMPTS{1, 3, 4} = '请把这段声音和内心转换过的声音进行比较 ';
        PROMPTS{1, 3, 5} = '如果相同，请按下"J"键，否则请按下"K"键 ';
        PROMPTS{1, 3, 6} = '声音播放完后，你有2s的时间进行按键反应, 然后下一个试次将很快开始 ';
        PROMPTS{1, 3, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点  ';
        PROMPTS{1, 3, 8} = '并尽量避免眨眼或者头动.按键之后可以眨眼     ';
        PROMPTS{1, 3, 9} = '如果准备好了，请按下空格键；如果有疑问,请向主试示意';

    
        PROMPTS{1, 4, 1} = '走向任务    每一个试次中，你会听到由3个声音组成的序列 ';
        PROMPTS{1, 4, 2} = '请将声音记在心中，并按照三个音的相对音高，2s内在心中将它转化成下面四个种类中的一个： ';
        PROMPTS{1, 4, 3} = '（音调）"升高-升高" 或 "升高-降低" 或 "降低-升高" 或 "降低-降低"   ';
        PROMPTS{1, 4, 4} = '然后你会听到另一段声音，你需要进行同样的转换';
        PROMPTS{1, 4, 5} = '如果前后两段声音的种类相同，请按下"J"键，否则请按下"K"键 ';
        PROMPTS{1, 4, 6} = '声音播放完后，你有2s的时间进行按键反应, 然后下一个试次将很快开始';
        PROMPTS{1, 4, 7} = '在整个试次中，请用眼睛看着屏幕上的注视点 ';
        PROMPTS{1, 4, 8} = '并尽量避免眨眼或者头动。按键之后可以眨眼';
        PROMPTS{1, 4, 9} = '如果准备好了，请按下空格键；如果有疑问,请向主试示意.';

    
    PROMPTS{1, 5} = '练习阶段';
    
    PROMPTS{1, 6} = '接下来是正式实验. 准备好后请按下空格键开始';
    
        
    end
    %%
    %----------------------正式实验----------------------%
    
    for condition = 1 : 4
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
        while ~(keyCode(keyspace))
            [~, ~,keyCode] = KbCheck;
        end
        if keyCode(keyend)
            sca; PsychPortAudio('Close');
        end
        
        
        %呈现注视点，练习开始
        DrawFormattedText(w, '+', 'Center', 'Center', WHITE);
        Screen('Flip', w);
        
        AudioPlay(2 , condition);

       
    end
    
    WaitSecs(2);
    ListenChar(0); sca; PsychPortAudio('Close');
catch
    Screen('CloseAll')
    rethrow(lasterror)
    

end
%%
