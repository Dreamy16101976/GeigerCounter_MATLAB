% Geiger Counter in MATLAB
% Version 1.0
% лицензия GPL v3.0
% Alexey V. Voronin @ FoxyLab © 2015
% http://acdc.foxylab.com
% -----------------------------------
% для 32-битной версии MATLAB
% серия из нескольких измерений
clc; % очистка окна команд
close all;  % удаление фигур
disp('***** Geiger counter *****');
disp('***Moving average algorithm***');
disp('Alexey V. Voronin @ FoxyLab © 2015');
disp('http://acdc.foxylab.com');
disp('**************************');
% ввод длительности измерений, секунды
prompt = {'Measurement period, sec'};
defans = {'900'}; % по умолчанию 15 минут
answer = inputdlg(prompt,'Measurement period',1,defans);
[nums status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('T = %d sec',nums));
% ввод ширины окна "скользящего среднего", секунды
prompt = {'Moving average window size, sec'};
defans = {'900'}; % по умолчанию 15 минут
answer = inputdlg(prompt,'Moving average window size',1,defans);
[window status] = str2num(answer{1});
if ~status
    error('Incorrect value!');
end;
disp(sprintf('W = %d sec',window));
Fs = 44100; % частота оцифровки, Гц
% для winsound максимальная поддерживаемая частота 96 кГц
% обычно допускается частота в пределах 5000 ... 96000 Гц
duration = 1; % длительность измерения, 1 сек
threshold = 0.5; % граница импульса
pause = 5; % длина паузы в сэмплах
ai = analoginput('winsound'); % создание объекта аналогового ввода для звуковой карты - winsound (соответствует идентификатору устройства ID = 0 для первой звуковой карты)
% если в системе установлено несколько звуковых карт, то для выбора второй,
% третьей и т.д. карт необходимо использовать ai = analoginput('winsound', ID) ,
% где ID - номер карты (0,1,2,...)
addchannel(ai,1); % добавление аппаратного канала к объекту аналогового ввода
% канал 1 - моно-режим
% для перевода в стерео-режим надо добавить еще канал 2 - addchannel(AI1, 2);
set (ai, 'SampleRate', Fs); % установка частоты оцифровки
set (ai, 'SamplesPerTrigger', duration*Fs); % задание числа сэмплов для захвата
set (ai, 'TriggerType', 'Manual'); % ручной старт захвата
set(ai,'TriggerRepeat',Inf);
start(ai); % готовность к началу захвата
MAs = []; % создаем массив для хранения всех MA
MABuffer = []; % создаем массив для подсчета MA
MASize = window; % размер буфера равен размеру окна
MACount = 0; % сброс счетчика заполнения буфера
for m =1:1:MASize % очистка буфера
    MABuffer(m) = 0;
end;
pulse = false; % сброс флага импульса
pauseCount = 0; % обнуление длительности паузы
count = 0; % обнуление счетчика MA
trigger(ai); % начало захвата
while (count < nums) % цикл измерений
    data = getdata(ai); % чтение данных
    % ожидание считывания всех данных
    trigger(ai); % старт захвата данных
    size = length(data); % размер массива данных
    pulseCount = 0; % обнуление счетчика импульсов в измерении
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
                pauseCount = pauseCount + 1; % инкремент счетчика длительности паузы       
                if (pauseCount > pause)
                % если пауза в течение нужного времени 
                    pulse = false; % флаг импульса спущен, будем ждать нового импульса
                    pulseCount = pulseCount + 1; % инкремент счетчика импульсов
                    pauseCount = 0; % обнуление длительности паузы
                end
            else
            % пауза прервана досрочно
                pauseCount = 0;
            end
        end        
    end;
    % инкремент счетчика заполнения буфера
    if (MACount < MASize) 
        MACount = MACount + 1; 
    end;
    % смещение данных в буфере вверх
    m = MASize;
    while m>1
        MABuffer(m) = MABuffer(m-1);
        m = m-1;
    end;
    % сохранение текущего результата измерений в буфере
    MABuffer(1) = pulseCount;
    % подсчет MA
    MA = 0;
    for m =1:1:MACount
        MA = MA+MABuffer(m);
    end;
    MA = MA / MACount * 60 / duration; % усредняем MA за 1 минуту 
    disp(strcat(sprintf('Full = %0.1f',MACount/MASize*100),'%')); % вывод % заполнения буфера
    disp(sprintf('MA = %0.2f CPM',MA)); % вывод MA
    count = count + 1; % инкремент счетчика MA
    MAs(count) = MA; % сохранение MA
 end;
 % строим график MA
 x_s = [0:duration:(count-1)*duration]; % метки по оси x 
 h = figure(1);
 plot(x_s,MAs,'LineWidth',3); % график MA
 grid on;
 ylim([0 2*duration*60]); % пределы по оси OY
 title('Moving Average'); % заголовок графика
 xlabel('t, sec') % метка оси OX
 ylabel('MA, CPM') % метка оси OY
 % сохранение MA в файле
 formatOut = 'yyyymmddHHMMSS'; % формат даты-времени
 unique = datestr(now,formatOut);
 unique_png = strcat(unique,'.png'); % составление имени png-файла  
 saveas(h, unique_png, 'png'); % сохранение графика в png-файл
 close(h); % закрытие построенного графика для экономии памяти
 unique_txt = strcat(unique,'.txt');  % составление имени txt-файла
 dlmwrite(unique_txt,MAs,'precision',6)
 MA_min = min(MAs); % минимальное число импульсов
 MA_max = max(MAs); % максимальное число импульсов
 disp(sprintf('Min = %0.2f CPM',MA_min)); % вывод минимального CPM
 disp(sprintf('Max = %0.2f CPM',MA_max)); % вывод максимального CPM
 stop(ai); % предотвращение запуска захвата для объекта аналогового ввода
 delete(ai); % удаление объекта аналогового ввода для освобождения памяти и других физических ресурсов
 clear ai; % удаление завершенного объекта из рабочего пространства MATLAB
 clear all; % удаление всех объектов из памяти