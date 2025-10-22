% --- 假定 add_col 已由上层代码设置好 ---
add_col = 4; % 示例

    % ===== 用户需修改的部分：把你的矩阵按顺序放入 matrices 列表 =====
    matrices = {G1_raw, G3_raw, G4_raw, G6_raw, G9_raw, G12_raw}; % 示例：6 个矩阵
    % ===================================================================

    % ---------- 方案 A：按 class_sizes 顺序分配（推荐） ----------
    % class_sizes 的和必须等于 numel(matrices)
    % 例：4 类，分别包含 [2,1,2,1] 个矩阵 --> 总和 6
    class_sizes = [2, 2, 1, 1];
    % ---------------------------------------------------------------

    % ---------- 方案 B（可选）：显式为每个矩阵指定类 ----------
    % 如果你想显式映射而不是顺序分配，取消方案 A 的使用并用下面的 class_map
    % class_map = [1 1 2 3 3 4]; % 每个元素对应 matrices 中同索引矩阵的类号
    % n_classes = max(class_map);
    % ---------------------------------------------------------------

    % 下面自动根据选用方案构造 class_map（不需要同时使用 A 和 B）
    if exist('class_sizes','var') && ~isempty(class_sizes)
        if sum(class_sizes) ~= numel(matrices)
            error('sum(class_sizes) must equal number of matrices (%d).', numel(matrices));
        end
        % 构建 class_map（按顺序分配）
        class_map = zeros(1, numel(matrices));
        idx = 1;
        for cls = 1:numel(class_sizes)
            for t = 1:class_sizes(cls)
                class_map(idx) = cls;
                idx = idx + 1;
            end
        end
        n_classes = numel(class_sizes);
    elseif exist('class_map','var') && ~isempty(class_map)
        if numel(class_map) ~= numel(matrices)
            error('class_map length must equal number of matrices.');
        end
        n_classes = max(class_map);
    else
        error('Please provide either class_sizes or class_map.');
    end

    % --------- 处理每个矩阵，将最后 add_col 替换为 n_classes*add_col ---------
    n_m = numel(matrices);
    result = cell(size(matrices));
    for idx = 1:n_m
        A = matrices{idx};
        if size(A,2) < add_col
            error('Matrix %d has fewer columns (%d) than add_col (%d).', idx, size(A,2), add_col);
        end

        lastCols = A(:, end-add_col+1:end);         % 取出最后 add_col 列
        B = zeros(size(A,1), n_classes * add_col);  % 扩展块，宽度为 n_classes * add_col
        cls = class_map(idx);                       % 当前矩阵属于第 cls 类
        pos = (cls-1)*add_col + (1:add_col);        % 在 B 中应该放置的位置
        B(:, pos) = lastCols;                       % 填入

        ncolA = size(A,2);
        new_ncol = ncolA + (n_classes-1)*add_col;   % 新总列数
        C = zeros(size(A,1), new_ncol);
        % 复制原矩阵除最后 add_col 之外的部分
        C(:, 1:(ncolA - add_col)) = A(:, 1:(ncolA - add_col));
        % 将扩展块放到尾部
        C(:, (ncolA - add_col + 1):new_ncol) = B;

        result{idx} = C;
    end

    [G1_raw, G3_raw, G4_raw, G6_raw, G9_raw, G12_raw] = deal(result{:});