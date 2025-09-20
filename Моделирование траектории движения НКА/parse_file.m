
% Основное использование
[almanac_data, valid_satellites] = parse_gps_almanac('mcct_250718.agp.txt');

% Вывод информации о всех активных спутниках
for i = 1:length(almanac_data)
    print_satellite_info(almanac_data(i));
end

% Фильтрация по конкретным PRN
gps_satellites = filter_by_prn(almanac_data, [1, 5, 10, 15]);

% Сохранение данных в MAT-файл
save('gps_almanac_data.mat', 'almanac_data', 'valid_satellites');

% Создание таблицы с основными параметрами
prn_list = [almanac_data.prn]';
health_list = [almanac_data.health]';
eccentricity_list = [almanac_data.eccentricity]';

data_table = table(prn_list, health_list, eccentricity_list, ...
    'VariableNames', {'PRN', 'Health', 'Eccentricity'});
disp(data_table);