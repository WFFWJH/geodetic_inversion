
[lon,lat,unw] = grdread2("C:\Users\Administrator\Desktop\testgit\geodetic_inversion\WORK1\myama\los_ll_low.grd");


% 绘图
figure;
h=imagesc(lon,lat, unw);   % 指定坐标范围

% 创建 AlphaData 矩阵（1 = 不透明，0 = 完全透明）
alphaData = ones(size(unw)); % 默认全不透明
alphaData(isnan(unw)) = 0;   % NaN 位置设为透明

% 应用透明度设置
set(h, 'AlphaData', alphaData); % 关键步骤：设置透明度

colormap('jet');                 % 设置颜色映射
colorbar;                        % 显示颜色条
axis xy;                         % 确保y轴向上
axis equal tight;                % 保持比例+紧贴数据
xlabel('X轴');
ylabel('Y轴');
title('imagesc绘制二维函数');