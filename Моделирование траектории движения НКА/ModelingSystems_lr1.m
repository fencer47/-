%% Моделирование траектории движения НКА для GPS за 12 часов

% Чтение альманаха из файла 
[almanac_data, valid_satellites] = parse_gps_almanac('mcct_250718.agp.txt');

% Извлечение параметров только для здоровых спутников
valid_indices = find(valid_satellites);
eccentricity = [almanac_data(valid_indices).eccentricity];
argument_perigee = [almanac_data(valid_indices).argument_perigee]; % ω 
inclination = [almanac_data(valid_indices).inclination]; % i0
mean_anomaly0 = [almanac_data(valid_indices).mean_anomaly]; % M0
Omega0 = [almanac_data(valid_indices).Om0]; % Ω0 
sqrt_a = [almanac_data(valid_indices).sqrt_semi_major_axis]; % sqrt(A)
t0_UTC = [almanac_data(valid_indices).epoch_time_utc]; % toa

% Константы
mu = 3.986004418e14; % Гравитационный параметр Земли [м^3/с^2]
omega_e = 7.2921151467e-5; % Угловая скорость вращения Земли [рад/с]
R_earth = 6371000; % Радиус Земли [м]

% ========================================================================
% НАСТРАИВАЕМЫЕ ПАРАМЕТРЫ ТОЧКИ НА ЗЕМЛЕ
% Задайте координаты вашей точки здесь:
latitude = 55.7558;   % Широта в градусах (Москва)
longitude = 37.6173;  % Долгота в градусах (Москва)
height = 0;           % Высота над уровнем моря [м] (по условию задачи = 0)
point_name = 'Москва'; % Название точки


lat_rad = deg2rad(latitude);
lon_rad = deg2rad(longitude);

% Расчет координат точки в земной системе координат 
N = R_earth / sqrt(1 - 0.00669437999014 * sin(lat_rad)^2); 
x_point = (N + height) * cos(lat_rad) * cos(lon_rad);
y_point = (N + height) * cos(lat_rad) * sin(lon_rad);
z_point = (N * (1 - 0.00669437999014) + height) * sin(lat_rad);
% ========================================================================

% Время моделирования
start_time = min(t0_UTC); % Начало моделирования
duration = 12 * 3600; 
time_step = 10 * 60; 
time_vector = start_time : time_step : (start_time + duration);
num_times = length(time_vector);
num_sats = length(valid_indices);

% X, Y, Z для каждого спутника в каждый момент времени
positions_ISK = zeros(3, num_sats, num_times);

% Цикл по времени
for t_idx = 1:num_times
    current_time = time_vector(t_idx);
    
    % Цикл по спутникам
    for sat_idx = 1:num_sats
        % 1) Разность времени от эпохи альманаха
        delta_t = current_time - t0_UTC(sat_idx);
        
        % 2) Расчет большой полуоси
        a = sqrt_a(sat_idx)^2; 
        
        % 3) Средняя аномалия M(t)
        n = sqrt(mu / a^3); 
        M_t = mean_anomaly0(sat_idx) + n * delta_t;
        
        % 4) Решение уравнения Кеплера для эксцентрической аномалии 
        E_t = M_t;
        for iter = 1:10
            E_new = M_t + eccentricity(sat_idx) * sin(E_t);
            if abs(E_new - E_t) < 1e-8
                break;
            end
            E_t = E_new;
        end
        
        % 5) Получение истинной аномалии
        numerator = sqrt(1 - eccentricity(sat_idx)^2) * sin(E_t);
        denominator = cos(E_t) - eccentricity(sat_idx);
        true_anomaly = atan2(numerator, denominator);
        
        % 6) Получение аргумента широты 
        u = argument_perigee(sat_idx) + true_anomaly;
        
        % 7) Определение расстояния до центра системы координат, используя аномалии эксцентриситета
        r = a * (1 - eccentricity(sat_idx) * cos(E_t));
        
        % 8) Координаты в орбитальной плоскости
        x_orb = r * cos(u);
        y_orb = r * sin(u);
        
        % 9) Координаты в инерциальной системе ИСК
        Omega = Omega0(sat_idx); 
        
        cos_Omega = cos(Omega);
        sin_Omega = sin(Omega);
        cos_i = cos(inclination(sat_idx));
        sin_i = sin(inclination(sat_idx));
        
        positions_ISK(1, sat_idx, t_idx) = x_orb * cos_Omega - y_orb * sin_Omega * cos_i;
        positions_ISK(2, sat_idx, t_idx) = x_orb * sin_Omega + y_orb * cos_Omega * cos_i;
        positions_ISK(3, sat_idx, t_idx) = y_orb * sin_i;
    end
end

%% Построение графика траекторий в ИСК
figure('Color', 'white', 'Position', [100, 100, 1000, 800]);
hold on; grid on; axis equal;
xlabel('X, м'); ylabel('Y, м'); zlabel('Z, м');
title(['Траектории движения GPS НКА в ИСК за 12 часов | Точка: ' point_name]);

% Рисуем Землю как сферу
[X_earth, Y_earth, Z_earth] = sphere(30);
surf(X_earth * R_earth, Y_earth * R_earth, Z_earth * R_earth,...
     'FaceAlpha', 0.1, 'EdgeColor', 'none', 'FaceColor', [0.7 0.9 1]);
colormap('winter');

% Отображаем точку на Земле
for t_idx = 1:num_times
    % Угол поворота Земли за время delta_t
    theta = omega_e * (time_vector(t_idx) - start_time);
    
    % Матрица поворота вокруг оси Z
    R = [cos(theta) -sin(theta) 0;
         sin(theta)  cos(theta) 0;
         0           0          1];
    
    % Координаты точки в ИСК 
    point_ISK = R * [x_point; y_point; z_point];
    
    % Рисуем точку каждый час
    if mod(t_idx, 6) == 1  
        plot3(point_ISK(1), point_ISK(2), point_ISK(3),...
              'ro', 'MarkerSize', 6, 'MarkerFaceColor', 'r');
    end
end

% 
plot3(x_point, y_point, z_point, 'ro', 'MarkerSize', 12,...
      'MarkerFaceColor', 'r', 'LineWidth', 2);

% Цикл по спутникам для построения траекторий
colors = lines(num_sats); 
for sat_idx = 1:num_sats
    % Извлекаем координаты для i-го спутника за все время
    x_traj = squeeze(positions_ISK(1, sat_idx, :));
    y_traj = squeeze(positions_ISK(2, sat_idx, :));
    z_traj = squeeze(positions_ISK(3, sat_idx, :));
    
    % Рисуем траекторию
    plot3(x_traj, y_traj, z_traj, '.-', 'Color', colors(sat_idx, :),...
          'MarkerSize', 4, 'LineWidth', 1);
    
    % Отмечаем начальную позицию спутника
    plot3(x_traj(1), y_traj(1), z_traj(1), 'o', 'MarkerSize', 8,...
          'MarkerFaceColor', colors(sat_idx, :), 'Color', 'k');
end


legend_items = {'Земля', 'Точка измерения', 'Начало точки', 'Траектории НКА', 'Нач. положение НКА'};
legend(legend_items, 'Location', 'bestoutside');
view(3);
rotate3d on; 
hold off;

%% Дополнительный 2D график для наглядности
figure('Color', 'white', 'Position', [200, 200, 1200, 500]);

% Проекция на плоскость X-Y
subplot(1,2,1);
hold on; grid on; axis equal;
plot(0, 0, 'bo', 'MarkerSize', 15, 'MarkerFaceColor', 'b'); % Центр Земли
rectangle('Position', [-R_earth, -R_earth, 2*R_earth, 2*R_earth],...
          'Curvature', [1,1], 'EdgeColor', 'b', 'LineStyle', '--'); % Земля

for sat_idx = 1:num_sats
    x_traj = squeeze(positions_ISK(1, sat_idx, :));
    y_traj = squeeze(positions_ISK(2, sat_idx, :));
    plot(x_traj, y_traj, '.-', 'Color', colors(sat_idx, :), 'MarkerSize', 3);
end
xlabel('X, м'); ylabel('Y, м');
title('Проекция траекторий на плоскость X-Y (ИСК)');

% Проекция на плоскость X-Z
subplot(1,2,2);
hold on; grid on; axis equal;
plot(0, 0, 'bo', 'MarkerSize', 15, 'MarkerFaceColor', 'b'); % Центр Земли
rectangle('Position', [-R_earth, -R_earth, 2*R_earth, 2*R_earth],...
          'Curvature', [1,1], 'EdgeColor', 'b', 'LineStyle', '--'); % Земля

for sat_idx = 1:num_sats
    x_traj = squeeze(positions_ISK(1, sat_idx, :));
    z_traj = squeeze(positions_ISK(3, sat_idx, :));
    plot(x_traj, z_traj, '.-', 'Color', colors(sat_idx, :), 'MarkerSize', 3);
end
xlabel('X, м'); ylabel('Z, м');
title('Проекция траекторий на плоскость X-Z (ИСК)');