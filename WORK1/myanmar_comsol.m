%%

N_layer = 6;
bias_wp = 1.3;
W = 45e3;
wp_factor = zeros(N_layer, 1);
for k = 1:N_layer
    wp_factor(k) = bias_wp^(k - 1);
end
wp_top = W / sum(wp_factor);

wp_layer = zeros(N_layer, 1);
for k = 1:N_layer
    wp_layer(k) = wp_top * bias_wp^(k - 1);
end

wp_up = zeros(N_layer,1);
for k = 1:N_layer
    wp_up(k) = sum(wp_layer(1:k));
end
wp_down = wp_up-wp_layer;


lp_top = 1.000000e3;
bias_lp = 1.3;
L = 523.48e3;
lp_every_layer = zeros(N_layer,1);
num_every_layer = zeros(N_layer,1);
for j = 1:N_layer
    lp_this_layer_rough = lp_top * bias_lp^(j - 1);
    N_this_layer = round(L/lp_this_layer_rough);
    if N_this_layer == 0
        lp_this_layer = L; % in case that one segment is really small
        N_this_layer = 1;
    else
        lp_this_layer = L / N_this_layer;
        lp_every_layer(j) = lp_this_layer;
        num_every_layer(j) = N_this_layer;
    end
end

% COMSOL Unit is KM, but my slip unit is M.
% wp_down = round(wp_down/1000,4);
% wp_up = round(wp_up/1000,4);
% lp_every_layer = round(lp_every_layer/1000,4);
wp_layer = wp_layer/1000;
wp_down = wp_down/1000;
wp_up = wp_up/1000;
lp_every_layer = lp_every_layer/1000;
patch_num = sum(num_every_layer);

% 定义路径列表
sample_insar_data = [...
    "./myanmar/D106/LOS/los_samp1.mat", ...
    "./myanmar/D33/LOS/los_samp1.mat", ...
    "./myanmar/A143/LOS/los_samp1.mat", ...
    "./myanmar/A70/LOS/los_samp1.mat"];
sample_azi_path = [...
    "./myanmar/D106/AZI/los_samp1.mat", ...
    "./myanmar/D33/AZI/los_samp1.mat", ...
    "./myanmar/A143/AZI/los_samp1.mat", ...
    "./myanmar/A70/AZI/los_samp1.mat"];

insar_tracks_num = length(sample_insar_data);
azi_tracks_num = length(sample_azi_path);

% 初始化存储数据的结构体
insarData = struct(); % 存储InSAR数据
aziData = struct();   % 存储AZI数据

insar_point_nums = zeros(insar_tracks_num,1);
azi_point_nums = zeros(azi_tracks_num,1);
identifiers = ["D106"; "D33"; "A143"; "A70"];
% 循环读取并分类数据
for i = 1:insar_tracks_num
    % 提取路径标识符 (例如 'D106')
    % pathParts = strsplit(sample_insar_data{i}, '/');
    % identifier = pathParts{3}; % 对应路径中的标识符（如 D106）
    identifier = identifiers(i);
    % 读取InSAR数据并存入结构体
     load_data = load(sample_insar_data{i},'sampled_insar_data');
    insarData.(identifier) = load_data.sampled_insar_data;
    insar_point_nums(i) = size(insarData.(identifier),1);
    % 读取AZI数据并存入结构体
     load_data = load(sample_azi_path{i},'sampled_insar_data');
     aziData.(identifier) = load_data.sampled_insar_data;
     azi_point_nums(i) = size(aziData.(identifier),1);
end

insar_point_num = sum(insar_point_nums);
azi_point_num = sum(azi_point_nums);
sample_points_num = insar_point_num+azi_point_num;
sample_points = zeros(sample_points_num,6);

sample_points_class = [insar_point_nums;azi_point_nums];
total_sample_class = numel(sample_points_class);
sample_class_cumsum = [0;cumsum(sample_points_class)];
boundary_left = sample_class_cumsum(1:end-1)+1;
boundary_right = sample_class_cumsum(2:end);


for i = 1:insar_tracks_num

    identifier = identifiers(i);
    sample_points(boundary_left(i):boundary_right(i),:) = insarData.(identifier);
end
for i = 1:azi_tracks_num
    identifier = identifiers(i);
    sample_points(boundary_left(i+insar_tracks_num):boundary_right(i+insar_tracks_num),:) = aziData.(identifier);
end


%%
profile on;
G_raw_uvw = zeros(sample_points_num, 2*patch_num, 3);

mphopen("./myanmar_matlab_top1.mph");
model.component('comp1').physics('solid').feature('disp1').set('U0', [0.5; 0.5; 0]);
model.component('comp1').physics('solid').feature('disp2').set('U0', [-0.5; 0.5; 0]);

for i = 1:1
    lp = lp_every_layer(i);
    model.component('comp1').geom('geom1').feature('wp2').set('quickz', -wp_down(i));
    model.component('comp1').geom('geom1').feature('wp3').set('quickz', -wp_up(i));
    for j = 1:num_every_layer(i)
        model.component('comp1').geom('geom1').feature('wp5').set('transdispl', [0 0 lp*(j-1)]);
        model.component('comp1').geom('geom1').feature('wp6').set('transdispl', [0 0 lp]);
        fprintf("%f   %f \n",lp*(j-1),lp*(j));
        % strike slip
        model.component('comp1').physics('solid').feature('disp1').set('Direction', {'free'; 'prescribed'; 'free'});
        model.component('comp1').physics('solid').feature('disp2').set('Direction', {'free'; 'prescribed'; 'free'});

        model.sol('sol1').runAll;
         [u,v, w]= mphinterp(model,{'u','v','w'},'coord',[sample_points(:,1),sample_points(:,2),zeros(size(sample_points(:,1),1),1)]'/1000);
        G_raw_uvw(:,sum(num_every_layer(1:i-1))+j,:) = [u(:),v(:),w(:)];
         % dip slip
        model.component('comp1').physics('solid').feature('disp1').set('Direction', {'prescribed'; 'free'; 'free'});
        model.component('comp1').physics('solid').feature('disp2').set('Direction', {'prescribed'; 'free'; 'free'});
        model.sol('sol1').runAll;
        [u,v, w]= mphinterp(model,{'u','v','w'},'coord',[sample_points(:,1),sample_points(:,2),zeros(size(sample_points(:,1),1),1)]'/1000);
        G_raw_uvw(:,sum(num_every_layer)+sum(num_every_layer(1:i-1))+j,:) = [u(:),v(:),w(:)];
    end
end


mphopen("./myanmar_matlab_no_top.mph");
model.component('comp1').physics('solid').feature('disp1').set('U0', [0.5; 0.5; 0]);
model.component('comp1').physics('solid').feature('disp2').set('U0', [-0.5; 0.5; 0]);

for i = 2:N_layer
    lp = lp_every_layer(i);
    model.component('comp1').geom('geom1').feature('wp2').set('quickz', -wp_down(i));
    model.component('comp1').geom('geom1').feature('wp3').set('quickz', -wp_up(i));

    % if i==5
    %     k = 135;
    % else
    %     k = 1;
    % end
        fprintf("第 %d 层 %f   %f \n",i,-wp_down(i),-wp_up(i));

    for j = 1:num_every_layer(i)
        model.component('comp1').geom('geom1').feature('wp5').set('transdispl', [0 0 lp*(j-1)]);
        model.component('comp1').geom('geom1').feature('wp6').set('transdispl', [0 0 lp]);
        fprintf("%f   %f \n",lp*(j-1),lp*(j));
        % strike slip
        model.component('comp1').physics('solid').feature('disp1').set('Direction', {'free'; 'prescribed'; 'free'});
        model.component('comp1').physics('solid').feature('disp2').set('Direction', {'free'; 'prescribed'; 'free'});

        model.sol('sol1').runAll;
         [u,v, w]= mphinterp(model,{'u','v','w'},'coord',[sample_points(:,1),sample_points(:,2),zeros(size(sample_points(:,1),1),1)]'/1000);
        G_raw_uvw(:,sum(num_every_layer(1:i-1))+j,:) = [u(:),v(:),w(:)];
         % dip slip
        model.component('comp1').physics('solid').feature('disp1').set('Direction', {'prescribed'; 'free'; 'free'});
        model.component('comp1').physics('solid').feature('disp2').set('Direction', {'prescribed'; 'free'; 'free'});
        model.sol('sol1').runAll;
        [u,v, w]= mphinterp(model,{'u','v','w'},'coord',[sample_points(:,1),sample_points(:,2),zeros(size(sample_points(:,1),1),1)]'/1000);
        G_raw_uvw(:,sum(num_every_layer)+sum(num_every_layer(1:i-1))+j,:) = [u(:),v(:),w(:)];
    end
end


save("Green_comsol.mat","G_raw_uvw","sample_points");

profile off;
profile viewer;

% %% top test
% mphopen("./myanmar_matlab_no_top.mph");
% 
% model.sol('sol1').runAll;
% mphinterp(model,{'u'},'coord',[122.99 -171.40 0]')


%%
load("Green_comsol.mat")
G_raw_uvw_los_strike = G_raw_uvw(1:insar_point_num,1:patch_num,:);
G_raw_uvw_los_dip = G_raw_uvw(1:insar_point_num,1+patch_num:2*patch_num,:);
G_raw_uvw_azi_strike  = G_raw_uvw(insar_point_num+1:sample_points_num,1:patch_num,:);
G_raw_uvw_azi_dip = G_raw_uvw(insar_point_num+1:sample_points_num,1+patch_num:2*patch_num,:);

sample_points_enu = sample_points(:,4:6);
los_enu = sample_points_enu(1:insar_point_num,:);
azi_enu = sample_points_enu(insar_point_num+1:sample_points_num,1:2);

G_raw_los_strike = sum(G_raw_uvw_los_strike .* reshape(los_enu, [insar_point_num, 1, 3]), 3);
G_raw_los_dip = sum(G_raw_uvw_los_dip .* reshape(los_enu, [insar_point_num, 1, 3]), 3);

% convert the LOS angle to heading angle
azi_theta = -atan2d(azi_enu(:,2),azi_enu(:,1)) - 180;
cos_theta = cosd(azi_theta);
sin_theta = sind(azi_theta);
G_raw_azi_strike = bsxfun(@times, G_raw_uvw_azi_strike(:, :, 1), sin_theta) + bsxfun(@times, G_raw_uvw_azi_strike(:, :, 2), cos_theta);
G_raw_azi_dip = bsxfun(@times, G_raw_uvw_azi_dip(:, :, 1), sin_theta) + bsxfun(@times, G_raw_uvw_azi_dip(:, :, 2), cos_theta);
G_raw = [G_raw_los_strike, G_raw_los_dip; G_raw_azi_strike , G_raw_azi_dip];
d_raw = sample_points(:,3)*1e-5;

% the following loop index ii, jj, kk mean:
   % ii -- which fault segment
   % jj -- which layer of this segment
   % kk -- which patch in this layer of this segment

   % smooth between patches in the same layer and same fault segment
G_smooth_every_layer = zeros(patch_num*2-2*length(num_every_layer),patch_num*2);
Fdip = 3;

for jj = 1:length(num_every_layer)
    for kk = 1:num_every_layer(jj)-1         % impose 1st derivative in length
        % strike + dip (2 rows)
        % patches in previous segments + patches at top layers of
        % this segment + number of this patch
        indx_minus_strike = sum(num_every_layer(1:jj-1)) + kk;
        indx_minus_dip = indx_minus_strike + patch_num;
        indx_plus_strike =  sum(num_every_layer(1:jj-1)) + kk + 1;
        indx_plus_dip = indx_plus_strike + patch_num;
        G_smooth_every_layer(indx_minus_strike+1-jj,indx_minus_strike) = -1; %row should -1 each time passes a layer
        G_smooth_every_layer(indx_minus_dip-length(num_every_layer)+1-jj,indx_minus_dip) = -Fdip;
        G_smooth_every_layer(indx_minus_strike+1-jj,indx_plus_strike) = 1;
        G_smooth_every_layer(indx_minus_dip-length(num_every_layer)+1-jj,indx_plus_dip) = Fdip;
        % disp([indx_minus_strike,indx_plus_strike,indx_minus_dip,indx_plus_dip]);
    end
end

   % smooth between patches in the adjacent layer and same fault segment
% isequal(smooth, G_smooth_every_layer)

G_smooth_layers = [];  
for jj = 1:length(num_every_layer)-1   % from top layer to the (bottom-1) layer
    for kk = 1:num_every_layer(jj)
        Lp_top_left = (kk-1)*lp_every_layer(jj);
        Lp_top_right = kk*lp_every_layer(jj);
        for kk_down = 1:num_every_layer(jj+1)
            Lp_bottom_left = (kk_down-1)*lp_every_layer(jj+1);
            Lp_bottom_right = kk_down*lp_every_layer(jj+1);

            % be careful with the "=" sign!
            % only left = left; right = right
            col = zeros(2,patch_num*2);
            if (abs(Lp_top_left - Lp_bottom_left) < 1e-3) || (abs(Lp_top_right - Lp_bottom_right) < 1e-3) ...
                    || (Lp_top_left < Lp_bottom_left && Lp_bottom_left < Lp_top_right) ...         % can not only be adjacent at the boundary
                    || (Lp_top_left < Lp_bottom_right && Lp_bottom_right < Lp_top_right)          % has contact
                % || (Lp_top_left > Lp_bottom_left && Lp_bottom_right > Lp_top_right)
                indx_minus_strike = sum(num_every_layer(1:jj-1))  + kk;
                indx_minus_dip = indx_minus_strike + patch_num;
                indx_plus_strike = sum(num_every_layer(1:jj)) + kk_down;
                indx_plus_dip = indx_plus_strike + patch_num;
                col(1,indx_minus_strike) = -1;
                col(2,indx_minus_dip) = -Fdip;
                col(1,indx_plus_strike) = 1;
                col(2,indx_plus_dip) = Fdip;
                G_smooth_layers = [G_smooth_layers; col];
                % fprintf("第 %d 层第%d 个 和下一层第%d个\n",jj,kk,kk_down);
                % smooth = [smooth;col];
                %              disp([indx_minus_strike,indx_plus_strike,indx_minus_dip,indx_plus_dip]);
            elseif Lp_top_right<Lp_bottom_left
                break
            end
        end
    end
end
%%
lamba = 10;

G_smooth = [G_smooth_every_layer;G_smooth_layers];
smooth_col = size(G_smooth,1);
G = [G_raw;G_smooth*lamba/smooth_col];

d = [double(d_raw);zeros(smooth_col,1)];

slip_max = 10;
lb=-slip_max*ones(2*patch_num,1);  %lower bound in cm
ub= slip_max*ones(2*patch_num,1);  %upper bound
lb(patch_num+1:2*patch_num) = -slip_max;   % dominated by strike slip
ub(patch_num+1:2*patch_num) = slip_max;
options = optimset('LargeScale','on','DiffMaxChange',1e-1,'DiffMinChange',1e-12, ...
    'TolCon',1e-12,'TolFun',1e-12,'TolPCG',1e-12,'TolX',1e-12,'MaxIter',1e9,'MaxPCGIter',1e9','Diagnostics', 'on','Display', 'iter');

% 完整的最小二乘求解代码
% options = optimoptions('lsqlin',...
%     'Algorithm', 'interior-point',...
%     'Display', 'iter',...
%     'MaxIterations', 5000,...
%     'OptimalityTolerance', 1e-6,...
%     'ConstraintTolerance', 1e-6,...
%     'StepTolerance', 1e-6,...
%     'FunctionTolerance', 1e-6,...
%     'LinearSolver', 'auto',...
%     'Diagnostics', 'on');


[u,resnorm,residual,exitflag] = lsqlin(G,d,[],[],[],[],lb,ub,[],options);

rms0 = sum(d_raw.^2);
rms1 = sum((G_raw*u-d_raw).^2);
redu_perc = 100*(rms0-rms1)/rms0;
fprintf('rms misfit (dat., res.) = %e %e (%f%%) \n',rms0,rms1,redu_perc);
fprintf('RMS: %f\n',rms(G_raw*u-d_raw));
fprintf('resnorm, resid. = %e %e \n',sqrt(resnorm),mean(residual));
fprintf('exitflag is %d\n',exitflag); 

visualize_fault_slip(wp_layer, lp_every_layer, num_every_layer, u);

function visualize_fault_slip(wp_layer, lp_every_layer, num_every_layer, u)
    % 计算总块数
    total_patches = sum(num_every_layer);
    
    % 检查输入向量长度是否匹配
    if length(u) ~= 2 * total_patches
        error('位移向量 u 的长度应与总块数的两倍匹配');
    end
    
    % 提取走滑和倾滑分量
    slip_strike = u(1:total_patches);       % 走滑分量
    slip_dip = u(total_patches+1:end);      % 倾滑分量
    
    % 计算总位移量（平方和开根号）
    total_slip = sqrt(slip_strike.^2 + slip_dip.^2);
    
    % 创建新图形
    figure;
    hold on;
    axis equal;
    axis([0 550 -50 0])
    xlabel('沿走向方向 (km)');
    ylabel('沿倾向方向 (km)');
    title('断层滑动分布可视化');
    
    % 设置颜色映射
    colormap(jet);
    clim([min(total_slip), max(total_slip)]);
    colorbar;
    ylabel(colorbar, '总位移量 (m)');
    
    % 初始化当前高度位置
    current_y = 0;
    patch_counter = 1;  % 用于跟踪当前块索引

    % 计算最大位移量用于归一化箭头长度
    max_slip = max(total_slip);
    if max_slip == 0
        max_slip = 1; % 避免除以零
    end
    
    % 循环处理每一层
    for layer = 1:length(wp_layer)
        layer_height = wp_layer(layer);
        num_in_layer = num_every_layer(layer);
        
        % 计算每个小块的宽度
        patch_width = lp_every_layer(layer);
        
        % 循环处理当前层中的每个小块
        for patch_in_layer = 1:num_in_layer
            % 计算当前小块的左下角坐标
            x_start = (patch_in_layer - 1) * patch_width;
            y_start = current_y;
            
            % 计算当前小块的四个角点
            x = [x_start, x_start + patch_width, x_start + patch_width, x_start];
            y = [y_start, y_start, y_start - layer_height, y_start - layer_height];
            
            % 计算中心点（用于绘制箭头）
            center_x = x_start + patch_width / 2;
            center_y = y_start + layer_height / 2;
            
            % 获取当前块的总位移量
            current_slip = total_slip(patch_counter);
            
            % 绘制矩形块
            patch(x, y, current_slip, 'EdgeColor', 'k', 'LineWidth', 0.5);
            

                        % 归一化箭头长度
                                % 计算归一化因子（基于块尺寸）
        norm_factor = min(patch_width, layer_height) * 2; % 箭头最大长度为块尺寸的40%
            if current_slip > 0
                % 计算归一化比例
                scale_factor = norm_factor / max_slip;
                
                % 绘制归一化箭头
                quiver(center_x, center_y, ...
                       slip_strike(patch_counter) * scale_factor, ...
                       slip_dip(patch_counter) * scale_factor, ...
                       'AutoScale', 'off', 'Color', 'k', 'LineWidth', 1.5, ...
                       'MaxHeadSize', 0.5);
            else
                % 对于零位移，绘制一个小点
                plot(center_x, center_y, 'k.', 'MarkerSize', 6);
            end

            
            % 更新块计数器
            patch_counter = patch_counter + 1;
        end
        
        % 更新y位置到下一层的起始位置
        current_y = current_y - layer_height;
    end
    
    % 添加图例
    legend('断层块', '位移方向', 'Location', 'best');
    
    % 优化图形显示
    hold off;
end