% Дополнительная функция для вывода информации о спутнике
function print_satellite_info(sat_data)
% PRINT_SATELLITE_INFO Выводит информацию о спутнике
    fprintf('PRN: %2d | Health: %d\n', sat_data.prn, sat_data.health);
    fprintf('Эпоха: %02d.%02d.%04d, UTC: %d сек\n', ...
        sat_data.epoch_day, sat_data.epoch_month, sat_data.epoch_year, sat_data.epoch_time_utc);
    fprintf('GPS неделя: %d, время: %d сек\n', sat_data.gps_week, sat_data.gps_time);
    fprintf('Поправка времени: %.3e сек, скорость: %.3e сек/сек\n', ...
        sat_data.time_correction, sat_data.time_correction_rate);
    fprintf('Орбитальные параметры:\n');
    fprintf('  Om0: %.6f, скорость Om0: %.6f\n', sat_data.Om0, sat_data.Om0_rate);
    fprintf('  Наклонение: %.6f\n', sat_data.inclination);
    fprintf('  Аргумент перигея: %.6f\n', sat_data.argument_perigee);
    fprintf('  Эксцентриситет: %.6f\n', sat_data.eccentricity);
    fprintf('  SQRT(A): %.6f\n', sat_data.sqrt_semi_major_axis);
    fprintf('  Средняя аномалия: %.6f\n', sat_data.mean_anomaly);
    fprintf('----------------------------------------\n');
end