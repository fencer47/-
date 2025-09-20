function [almanac_data, valid_satellites] = parse_gps_almanac(filename)
% PARSE_GPS_ALMANAC Парсер файлов альманаха GPS в формате .agp
%   [almanac_data, valid_satellites] = parse_gps_almanac(filename)
%   Возвращает структуру с данными альманаха и список валидных спутников

% Чтение файла
fid = fopen(filename, 'r');
if fid == -1
    error('Не удалось открыть файл: %s', filename);
end

% Инициализация структур
almanac_data = struct();
valid_satellites = [];

line_count = 0;
satellite_count = 0;

while ~feof(fid)
    line_count = line_count + 1;
    line = fgetl(fid);
    
    if isempty(line) || all(isspace(line))
        continue; % Пропускаем пустые строки
    end
    
    % Обработка первой строки (заголовок эпохи)
    if mod(line_count, 3) == 1
        header_data = sscanf(line, '%d %d %d %d');
        if length(header_data) >= 4
            epoch_day = header_data(1);
            epoch_month = header_data(2);
            epoch_year = header_data(3);
            epoch_time_utc = header_data(4);
        end
        
    % Обработка второй строки (основные параметры спутника)
    elseif mod(line_count, 3) == 2
        satellite_data = sscanf(line, '%d %d %d %d %d %d %d %f %f %f %f');
        
        if length(satellite_data) >= 11
            satellite_count = satellite_count + 1;
            
            % Сохраняем данные спутника
            almanac_data(satellite_count).prn = satellite_data(1);
            almanac_data(satellite_count).health = satellite_data(2);
            almanac_data(satellite_count).gps_week = satellite_data(3);
            almanac_data(satellite_count).gps_time = satellite_data(4);
            almanac_data(satellite_count).day = satellite_data(5);
            almanac_data(satellite_count).month = satellite_data(6);
            almanac_data(satellite_count).year = satellite_data(7);
            almanac_data(satellite_count).almanac_time = satellite_data(8);
            almanac_data(satellite_count).time_correction = satellite_data(9);
            almanac_data(satellite_count).time_correction_rate = satellite_data(10);
            almanac_data(satellite_count).Om0_rate = satellite_data(11);
            
            % Сохраняем информацию об эпохе
            almanac_data(satellite_count).epoch_day = epoch_day;
            almanac_data(satellite_count).epoch_month = epoch_month;
            almanac_data(satellite_count).epoch_year = epoch_year;
            almanac_data(satellite_count).epoch_time_utc = epoch_time_utc;
        end
        
    % Обработка третьей строки (орбитальные параметры)
    elseif mod(line_count, 3) == 0
        orbital_data = sscanf(line, '%f %f %f %f %f %f');
        
        if length(orbital_data) >= 6 && satellite_count > 0
            almanac_data(satellite_count).Om0 = orbital_data(1);
            almanac_data(satellite_count).inclination = orbital_data(2);
            almanac_data(satellite_count).argument_perigee = orbital_data(3);
            almanac_data(satellite_count).eccentricity = orbital_data(4);
            almanac_data(satellite_count).sqrt_semi_major_axis = orbital_data(5);
            almanac_data(satellite_count).mean_anomaly = orbital_data(6);
            
            % Проверка здоровья спутника (health = 0 - активен)
            if almanac_data(satellite_count).health == 0
                valid_satellites = [valid_satellites, almanac_data(satellite_count).prn];
            end
        end
    end
end

fclose(fid);

% Удаляем неактивные спутники
active_mask = [almanac_data.health] == 0;
almanac_data = almanac_data(active_mask);

fprintf('Парсинг завершен.\n');
fprintf('Общее количество спутников: %d\n', satellite_count);
fprintf('Активных спутников: %d\n', sum(active_mask));
fprintf('Неактивных спутников: %d\n', satellite_count - sum(active_mask));

if ~isempty(valid_satellites)
    fprintf('Активные PRN: %s\n', mat2str(sort(valid_satellites)));
end
end


