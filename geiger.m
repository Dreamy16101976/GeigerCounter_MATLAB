% Geiger Counter in MATLAB
% Version 1.0
% Alexey V. Voronin @ FoxyLab © 2015
% http://acdc.foxylab.com
% -----------------------------------
% серия из нескольких измерений
clc; % очистка окна команд
close all;  % удаление фигур
disp('© 2015 acdc.foxylab.com');
disp('***** Geiger counter *****');
disp('**************************');
disp('***Moving average algorithm***');
prompt = {'Measurement period, sec'};
defans = {'900'};
answer = inputdlg(prompt,'Measurement period',1,defans);
[nums status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('T = %d sec',nums));
prompt = {'Moving average window size, sec'};
defans = {'900'};
answer = inputdlg(prompt,'Moving average window size',1,defans);
[window status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('W = %d sec',window));
Fs = 44100; % частота оцифровки
duration = 1; % длительность измерения = 1 сек
threshold = 0.5; % граница импульса
pause = 5; % длина паузы в сэмплах
ai = analoginput('winsound'); % creates the analog input object AI for a sound card having an ID of 0 (adaptor must be winsound)
addchannel(ai,1); 
set (ai, 'SampleRate', Fs); % set the sample rate
set (ai, 'SamplesPerTrigger', duration*Fs); % set number of samples to acquire
set (ai, 'TriggerType', 'Manual'); % set acquisition start type
set(ai,'TriggerRepeat',Inf);
start(ai); % The start command will start the acquisition running
MAs = []; % создаем массив для хранения всех MA
MABuffer = []; % создаем массив для подсчета MA
MASize = window;%размер буфера равен размеру окна
MACount = 0;%сброс счетчика заполнения буфера
for m =1:1:MASize %очистка буфераы
    MABuffer(m) = 0;
end;
pulse = false;%сброс флага импульса
pauseCount = 0;% обнуление длительности паузы
count = 0;%обнуление счетчика MA
trigger(ai);%начало захвата
while (count < nums) %цикл измерений
    data = getdata(ai); % And to read the data use the getdata function 
    trigger(ai);% the data samples will not be stored in the data acquisition engine until the TRIGGER command is issued
    % GETDATA is a "blocking" function. This means that it will wait until all data have been collected
    size = length(data);%размер массива данных
    pulseCount = 0;% обнуление счетчика импульсов в измерении
    for i = 1:1:size % цикл по всем сэмплам       
        % если импульс еще не начался
        if (pulse == false)
            if (abs(data(i))>threshold)
            % если уровень превышает предел, то поднимаем флаг начала импульса
                pulse = true;
            end
        else
        % если импульс уже начался
            if (abs(data(i))<=threshold)
            % если уровень ниже предела
                pauseCount = pauseCount + 1;% инкремент счетчика длительности паузы       
                if (pauseCount > pause)
                % если пауза в течение нужного времени 
                    pulse = false;% флаг импульса спущен, будем ждать нового импульса
                    pulseCount = pulseCount + 1;% инкремент счетчика импульсов
                    pauseCount = 0;% обнуление длительности паузы
                end
            else
            % пауза прервана досрочно
                pauseCount = 0;
            end
        end        
    end;
    %инкремент счетчика заполнения буфера
    if (MACount < MASize) 
        MACount = MACount + 1; 
    end;
    %смещение данных в буфере вверх
    m = MASize;
    while m>1
        MABuffer(m) = MABuffer(m-1);
        m = m-1;
    end;
    %сохранение текущего результата измерений в буфере
    MABuffer(1) = pulseCount;
    %подсчет MA
    MA = 0;
    for m =1:1:MACount
        MA = MA+MABuffer(m);
    end;
    MA = MA / MACount * 60 / duration; %усредняем MA за 1 минуту 
    disp(strcat(sprintf('Full = %0.1f',MACount/MASize*100),'%'));% вывод % заполнения буфера
    disp(sprintf('MA = %0.2f CPM',MA));% вывод MA
    count = count + 1;%инкремент счетчика MA
    MAs(count) = MA;%сохранение MA
 end;
 % строим график MA
 x_s = [0:duration:(count-1)*duration];%метки по оси x 
 h = figure(1);
 plot(x_s,MAs,'LineWidth',3);%график MA
 grid on;
 ylim([0 2*duration*60]); % пределы по оси OY
 title('Moving Average');
 xlabel('t, sec') % метка оси OX
 ylabel('MA, CPM') % метка оси OY
 %сохранение MA в файле
 formatOut = 'yyyymmddHHMMSS';
 unique = datestr(now,formatOut);
 % составляем имя файла
 unique_png = strcat(unique,'.png');  
 %Сохранение графика в файл c нужным расширением (смотри help)
 saveas(h, unique_png, 'png'); 
 close(h); %закрываем построенный график, чтоб не засорять память
 unique_txt = strcat(unique,'.txt');
 dlmwrite(unique_txt,MAs,'precision',6)
 MA_min = min(MAs); % минимальное число импульсов
 MA_max = max(MAs); % максимальное число импульсов
 disp(sprintf('Min = %0.2f CPM',MA_min));
 disp(sprintf('Max = %0.2f CPM',MA_max));
 stop(ai); % stop the analog input object from running
 delete(ai); % delete the analog input object to free memory and other physical resources
 % clears the finished object from the MATLAB workspace
 clear ai;
 clear all; % deletes all objects from memory