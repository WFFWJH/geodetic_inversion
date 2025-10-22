lons = [120.5, 93.90, 97.24];
lats = [30.3, 17.24, 23.73];


% lon = lons(1);
% lat = lats(1);
lon = lons;
lat = lats;

r_a = 6378137;
r_e = sqrt(0.006694379990141);

% r_a = 6378206.4; % clarke 1866 赤道半径 (米)
% r_e = sqrt(0.00676865799761); % 平方偏心率
get_utm_zone(lon)

% 2. 使用ll2xy函数计算 (基于原始代码)
[east1, north1] = ll2xy(lon, lat, 123); % 中央经线117°E
[east2, north2] = latlon2utm_matlab(lat,lon,123);
% [east2, north2, zone] = ll2utm(lat, lon, 'wgs84', 51);


proj = projcrs(32651);
[east3, north3] = projfwd(proj, lat, lon);
% 4. 使用PyProj获取参考值 (Python环境计算)
% 以下值基于PyProj计算:
%   from pyproj import Proj
%   p = Proj(proj='utm', zone=51, ellps='clrk66')
%   p(120.5, 30.3)
pyproj_easting = 259566.702; % 东坐标
pyproj_northing = 3354494.855; % 北坐标

% 5. 比较所有结果
fprintf('===== 结果比较 =====\n');
fprintf('方法            东坐标       北坐标\n');
fprintf('----------------------------------\n');
fprintf('ll2xy:       %.5f    %.5f\n', east1, north1);
fprintf('self:       %.5f    %.5f\n', east2, north2);
fprintf('projfwd:       %.5f    %.5f\n', east3, north3);
%% Fault

ref_lon = 95;
lon_eq = 95.33;
lat_eq = 19.61;
d2r = pi / 180;
[xo, yo] = ll2xy(lon_eq, lat_eq, ref_lon);
fault_data = load('fault');
lon_pt = [fault_data(:, 1); fault_data(:, 3)];
lat_pt = [fault_data(:, 2); fault_data(:, 4)];
nflt = size(fault_data, 1);

[xutm_pt, yutm_pt] = ll2xy(lon_pt, lat_pt, ref_lon);
xpt = xutm_pt - xo;
ypt = yutm_pt - yo;
strikes = zeros(1,nflt);
thetas = strikes;

% figure;
% subplot(1,2,1);
% plot(lon_pt,lat_pt)
% subplot(1,2,2);
% plot(xpt,ypt)

for kk = 1:nflt
    xstart = xpt(kk+nflt);
    ystart = ypt(kk+nflt);
    xend = xpt(kk);
    yend = ypt(kk);
    dx = xend - xstart; % negative constraint (the fault starts from the bottom to the top)
    dy = yend - ystart;

    L = sqrt(dx^2+dy^2);
    theta = atan2(dy, dx);
    strike1 = 90 - theta / d2r;

    if (strike1 < 0)
        strike1 = strike1 + 360;
    end
    strikes(kk) = strike1;
    thetas(kk) = (90 - strike1) * d2r;
    % fault_id = fault_id + 1;
    % model_segment = make_fault_segments(fault_id, xstart, ystart, zstart, strike1, dip_angle, L, W, N_layer, lp_top, bias_lp, bias_wp);
    % slip_model = [slip_model; model_segment];
end

%%
N_layer = 6;
bias_wp = 1.3;
W = 50e3;
wp_factor = zeros(N_layer, 1);
for k = 1:N_layer
    wp_factor(k) = bias_wp^(k - 1);
end
wp_top = W / sum(wp_factor);

wp_layer = zeros(N_layer, 1);
for k = 1:N_layer
    wp_layer(k) = wp_top * bias_wp^(k - 1);
end

lp_top = 1e3;
bias_lp = 1.3;
L = 523.48e3;
lp_layer = zeros(N_layer,1);
for j = 1:N_layer
    lp_this_layer_rough = lp_top * bias_lp^(j - 1);
    N_this_layer = round(L/lp_this_layer_rough);
    if N_this_layer == 0
        lp_this_layer = L; % in case that one segment is really small
        N_this_layer = 1;
    else
        lp_this_layer = L / N_this_layer;
        lp_layer(j) = lp_this_layer;
    end
end
wp_layer
lp_layer
%%
function zone = get_utm_zone(lon)

    zone = floor((lon+180)/6)+1;
end


function [xo, yo] = ll2xy(xi, yi, lon_c)
%
% [xo,yo]=ll2xy(xi,yi,lon_c);
%
% Last updated by Kang Wang on 11/09/2015
yold = yi;
if (yi < 0)
    yi = -yi;
end


%r_dtor=1.74532925199d-2;   %  = pi/180
r_dtor = pi / 180;
% i_ft=0;
i_ft = 0;
a_griddes = ['C', 'D', 'E', 'F', 'G', 'H', 'J', ...
    'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'U', ...
    'V', 'W', 'X'];
r_a=6378206.4d0;
r_e2=0.00676865799761d0;
% r_a = 6378137;
% r_e2 = 0.006694379990141;
r_k0 = 0.9996d0; %scale at center
r_lat0 = 0.0d0;
r_fe = 5e5;
r_fn(1) = 0;
r_fn(2) = 1e7; %

r_ep2 = r_e2 / (1.d0 - r_e2);
r_e4 = r_e2^2;
r_e6 = r_e2^3;
r_dtor = pi / 180;

r_v = zeros(length(xi(:)), 2);
xi = xi * r_dtor;
yi = yi * r_dtor;

i_zone = fix(mod(xi+3.d0*pi, 2.d0*pi)/(r_dtor * 6.d0)) + 1;
i_zone = max(min(i_zone, 60), 1);
% r_lon0 = -pi + 6.d0*r_dtor*(i_zone-1) + 3.d0*r_dtor % central meridian
%r_lon0 = lon_c;
r_lon0 = lon_c * r_dtor;
r_n = r_a ./ sqrt(1.d0-r_e2*sin(yi).^2);
r_t = tan(yi).^2;
r_t2 = r_t.^2;
r_c = r_ep2 * cos(yi).^2;
r_ba = (xi - r_lon0) .* cos(yi);
r_a2 = r_ba.^2;
r_a3 = r_ba .* r_a2;
r_a4 = r_ba .* r_a3;
r_a5 = r_ba .* r_a4;
r_a6 = r_ba .* r_a5;
r_m = r_a .* ((1.0d0 - r_e2 / 4 - 3.0d0 * r_e4 / 64.0d0 - 5.d0 * r_e6 / 256.d0) * ...
    yi - (3.d0 * r_e2 / 8.d0 + 3.d0 * r_e4 / 32.d0 + 45.d0 * r_e6 / ...
    1024.d0) * sin(2.d0*yi) + (15.d0 * r_e4 / 256.d0 + ...
    45.d0 * r_e6 / 1024.d0) * sin(4.d0*yi) - (35.d0 * r_e6 / 3072.d0) * ...
    sin(6.d0*yi));
r_m0 = r_a .* ((1.d0 - r_e2 / 4 - 3.d0 * r_e4 / 64.d0 - 5.d0 * r_e6 / 256.d0) * ...
    r_lat0 - (3.d0 * r_e2 / 8.d0 + 3.d0 * r_e4 / 32.d0 + ...
    45.d0 * r_e6 / 1024.d0) * sin(2.d0*r_lat0) + (15.d0 * r_e4 / ...
    256.d0 + 45.d0 * r_e6 / 1024.d0) * sin(4.d0*r_lat0) - ...
    (35.d0 * r_e6 / 3072.d0) * sin(6.d0*r_lat0));

r_v(:, 1) = r_k0 * r_n .* (r_ba + (1.d0 - r_t + r_c) .* r_a3 / 6.d0 ...
    +(5.d0 - 18.d0 * r_t + r_t2 + 72.d0 * r_c - 58.d0 * r_ep2) .* r_a5 / 120.d0);
r_v(:, 1) = r_v(:, 1) + r_fe;

r_v(:, 2) = r_k0 * (r_m - r_m0 + r_n .* tan(yi) .* (r_a2 / 2.d0 + ...
    (5.d0 - r_t + 9.d0 * r_c + 4.d0 * r_c.^2) .* (r_a4 / 24.d0) + ...
    (61.d0 - 58.d0 * r_t + r_t2 + 600.d0 * r_c - 330.d0 * r_ep2) .* ...
    (r_a6 / 720.d0)));
if yi >= 0
    r_v(:, 2) = r_v(:, 2) + r_fn(1);
else
    r_v(:, 2) = r_v(:, 2) + r_fn(2);
end

r_k = r_k0 * (1.d0 + (1.d0 + r_ep2 .* cos(yi).^2) .* (r_v(:, 1) - r_fe).^2 ./ ...
    (2.d0 * (r_k0.^2) .* r_n.^2));

i_gi = fix((yi ./ r_dtor + 80.d0)/8.d0) + 1;
i_gi = max(min(i_gi, 20), 1);
a_grid = a_griddes(i_gi);

xo = r_v(:, 1);
if (yold < 0)
    yo = -r_v(:, 2);
else
    yo = r_v(:, 2);
end

end


function [E, N] = latlon2utm_matlab(lon, lat, lon0)
% latlon2utm_matlab  将 WGS84 的经纬度转为自定义中央经线下的 UTM 投影
%   [E, N] = latlon2utm_matlab(lon, lat, lon0)
% 输入：
%   lon, lat — 经度、纬度（单位：deg），可以是标量，也可以是向量
%   lon0     — 自定义中央经线（单位：deg）
% 输出：
%   E, N     — 投影坐标（单位：m）

    % 1. 构造 Transverse Mercator 的 map projection structure
    mstruct = defaultm('tranmerc');
    % WGS84 椭球
    mstruct.geoid = referenceEllipsoid('wgs84');
    % 中央经线、中央纬线（这里纬度原点取 0）
    mstruct.origin = [0 lon0 0];
    % UTM 标准参数
    mstruct.scalefactor   = 0.9996;    % k₀
    mstruct.falseeasting  = 500000;    % x₀
    mstruct.falsenorthing = 0;         % 南半球时设 1e7

    % 2. 正算：将(lat, lon) → (E, N)
    [E, N] = mfwdtran(mstruct, lat, lon);
end
