% Geiger Counter in MATLAB
% Version 1.0
% �������� GPL v3.0
% Alexey V. Voronin @ FoxyLab � 2015
% http://acdc.foxylab.com
% -----------------------------------
% ��� 32-������ ������ MATLAB
% ����� �� ���������� ���������
clc; % ������� ���� ������
close all;  % �������� �����
disp('***** Geiger counter *****');
disp('***Moving average algorithm***');
disp('Alexey V. Voronin @ FoxyLab � 2015');
disp('http://acdc.foxylab.com');
disp('**************************');
% ���� ������������ ���������, �������
prompt = {'Measurement period, sec'};
defans = {'900'}; % �� ��������� 15 �����
answer = inputdlg(prompt,'Measurement period',1,defans);
[nums status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('T = %d sec',nums));
% ���� ������ ���� "����������� ��������", �������
prompt = {'Moving average window size, sec'};
defans = {'900'}; % �� ��������� 15 �����
answer = inputdlg(prompt,'Moving average window size',1,defans);
[window status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('W = %d sec',window));
Fs = 44100; % ������� ���������, ��
% ��� winsound ������������ �������������� ������� 96 ���
% ������ ����������� ������� � �������� 5000 ... 96000 ��
duration = 1; % ������������ ���������, 1 ���
threshold = 0.5; % ������� ��������
pause = 5; % ����� ����� � �������
ai = analoginput('winsound'); % �������� ������� ����������� ����� ��� �������� ����� - winsound (������������� �������������� ���������� ID = 0 ��� ������ �������� �����)
% ���� � ������� ����������� ��������� �������� ����, �� ��� ������ ������,
% ������� � �.�. ���� ���������� ������������ ai = analoginput('winsound', ID) ,
% ��� ID - ����� ����� (0,1,2,...)
addchannel(ai,1); % ���������� ����������� ������ � ������� ����������� �����
% ����� 1 - ����-�����
% ��� �������� � ������-����� ���� �������� ��� ����� 2 - addchannel(AI1, 2);
set (ai, 'SampleRate', Fs); % ��������� ������� ���������
set (ai, 'SamplesPerTrigger', duration*Fs); % ������� ����� ������� ��� �������
set (ai, 'TriggerType', 'Manual'); % ������ ����� �������
set(ai,'TriggerRepeat',Inf);
start(ai); % ���������� � ������ �������
MAs = []; % ������� ������ ��� �������� ���� MA
MABuffer = []; % ������� ������ ��� �������� MA
MASize = window; % ������ ������ ����� ������� ����
MACount = 0; % ����� �������� ���������� ������
for m =1:1:MASize % ������� ������
    MABuffer(m) = 0;
end;
pulse = false; % ����� ����� ��������
pauseCount = 0; % ��������� ������������ �����
count = 0; % ��������� �������� MA
trigger(ai); % ������ �������
while (count < nums) % ���� ���������
    data = getdata(ai); % ������ ������
    % �������� ���������� ���� ������
    trigger(ai); % ����� ������� ������
    size = length(data); % ������ ������� ������
    pulseCount = 0; % ��������� �������� ��������� � ���������
    for i = 1:1:size % ���� �� ���� �������       
        % ���� ������� ��� �� �������
        if (pulse == false)
            if (abs(data(i))>threshold)
            % ���� ������� ��������� ������, �� ��������� ���� ������ ��������
                pulse = true;
            end
        else
        % ���� ������� ��� �������
            if (abs(data(i))<=threshold)
            % ���� ������� ���� �������
                pauseCount = pauseCount + 1; % ��������� �������� ������������ �����       
                if (pauseCount > pause)
                % ���� ����� � ������� ������� ������� 
                    pulse = false; % ���� �������� ������, ����� ����� ������ ��������
                    pulseCount = pulseCount + 1; % ��������� �������� ���������
                    pauseCount = 0; % ��������� ������������ �����
                end
            else
            % ����� �������� ��������
                pauseCount = 0;
            end
        end        
    end;
    % ��������� �������� ���������� ������
    if (MACount < MASize) 
        MACount = MACount + 1; 
    end;
    % �������� ������ � ������ �����
    m = MASize;
    while m>1
        MABuffer(m) = MABuffer(m-1);
        m = m-1;
    end;
    % ���������� �������� ���������� ��������� � ������
    MABuffer(1) = pulseCount;
    % ������� MA
    MA = 0;
    for m =1:1:MACount
        MA = MA+MABuffer(m);
    end;
    MA = MA / MACount * 60 / duration; % ��������� MA �� 1 ������ 
    disp(strcat(sprintf('Full = %0.1f',MACount/MASize*100),'%')); % ����� % ���������� ������
    disp(sprintf('MA = %0.2f CPM',MA)); % ����� MA
    count = count + 1; % ��������� �������� MA
    MAs(count) = MA; % ���������� MA
 end;
 % ������ ������ MA
 x_s = [0:duration:(count-1)*duration]; % ����� �� ��� x 
 h = figure(1);
 plot(x_s,MAs,'LineWidth',3); % ������ MA
 grid on;
 ylim([0 2*duration*60]); % ������� �� ��� OY
 title('Moving Average'); % ��������� �������
 xlabel('t, sec') % ����� ��� OX
 ylabel('MA, CPM') % ����� ��� OY
 % ���������� MA � �����
 formatOut = 'yyyymmddHHMMSS'; % ������ ����-�������
 unique = datestr(now,formatOut);
 unique_png = strcat(unique,'.png'); % ����������� ����� png-�����  
 saveas(h, unique_png, 'png'); % ���������� ������� � png-����
 close(h); % �������� ������������ ������� ��� �������� ������
 unique_txt = strcat(unique,'.txt');  % ����������� ����� txt-�����
 dlmwrite(unique_txt,MAs,'precision',6)
 MA_min = min(MAs); % ����������� ����� ���������
 MA_max = max(MAs); % ������������ ����� ���������
 disp(sprintf('Min = %0.2f CPM',MA_min)); % ����� ������������ CPM
 disp(sprintf('Max = %0.2f CPM',MA_max)); % ����� ������������� CPM
 stop(ai); % �������������� ������� ������� ��� ������� ����������� �����
 delete(ai); % �������� ������� ����������� ����� ��� ������������ ������ � ������ ���������� ��������
 clear ai; % �������� ������������ ������� �� �������� ������������ MATLAB
 clear all; % �������� ���� �������� �� ������