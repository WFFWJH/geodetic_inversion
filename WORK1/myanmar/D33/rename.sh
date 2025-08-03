#!/bin/bash

# Step 1: 重命名文件
mv -v lke.grd look_e.grd
mv -v lkn.grd look_n.grd
mv -v lku.grd look_u.grd

# Step 2: 要链接的文件列表
FILES=("look_e.grd" "look_n.grd" "look_u.grd" "dem.grd")

# Step 3: 遍历目标子目录建立符号链接
for DIR in AZI LOS RNG; do
    echo "Processing directory: $DIR"
    for FILE in "${FILES[@]}"; do
        TARGET="../$FILE"
        LINK="$DIR/$FILE"
        ln -svf "$TARGET" "$LINK"
    done
done

