[lat, lon] = deal(30.3, 120.5);

% 1. 手动创建Clarke 1866椭球对象
% 精确参数来自原始代码
r_a = 6378206.4;       % 赤道半径 (米)
r_e = sqrt(0.00676865799761); % 平方偏心率

clarke66_vector = [r_a, r_e];  % 格式：[赤道半径, 偏心率]

% 2. 使用ll2xy函数计算 (基于原始代码)
[east1, north1] = ll2xy(lon, lat, 123); % 中央经线117°E
[east2, north2, zone] = ll2utm(lat,lon,'clk66');
% 3. 使用MATLAB投影函数计算 (使用手动创建的椭球)
utmzone1 = utmzone(lat, lon);
utmstruct = defaultm('utm'); 
utmstruct.zone = utmzone1;
utmstruct.geoid = clarke66_vector; % 使用向量形式 [a, e]
utmstruct = defaultm(utmstruct);
[easting_mat, northing_mat] = mfwdtran(utmstruct, lat, lon);

% 4. 使用PyProj获取参考值 (Python环境计算)
% 以下值基于PyProj计算:
%   from pyproj import Proj
%   p = Proj(proj='utm', zone=50, ellps='clrk66')
%   p(120.5, 30.3)
pyproj_easting = 259566.702;    % 东坐标
pyproj_northing = 3354494.855;  % 北坐标

% 5. 比较所有结果
fprintf('===== 结果比较 =====\n');
fprintf('方法            东坐标       北坐标\n');
fprintf('----------------------------------\n');
fprintf('ll2xy:       %.3f    %.3f\n', east1, north1);
fprintf('ll2utm:       %.3f    %.3f\n', east2, north2);
fprintf('Python(基准):%.3f    %.3f\n', pyproj_easting, pyproj_northing);
fprintf('MATLAB(手动):%.3f    %.3f\n', easting_mat, northing_mat);

% 计算差异
diff_ll_vs_py = [east1 - pyproj_easting, north1 - pyproj_northing];
diff_ll_vs_py1 = [east2 - pyproj_easting, north2 - pyproj_northing];
diff_mat_vs_py = [easting_mat - pyproj_easting, northing_mat - pyproj_northing];

fprintf('\n===== 差异分析 =====\n');
fprintf('ll2xy与Python差异:  东 %.3f m, 北 %.3f m\n', diff_ll_vs_py(1), diff_ll_vs_py(2));
fprintf('ll2utm与Python差异:  东 %.3f m, 北 %.3f m\n', diff_ll_vs_py1(1), diff_ll_vs_py1(2));
fprintf('MATLAB与Python差异: 东 %.3f m, 北 %.3f m\n', diff_mat_vs_py(1), diff_mat_vs_py(2));