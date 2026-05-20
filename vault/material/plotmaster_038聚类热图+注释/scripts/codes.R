# 载入R包：
library(ComplexHeatmap)
library(tidyverse)

# 构造数据：创建4组相关系数；
data <- data.frame(Control = runif(44, min = -1, max = 1),
                  PD = runif(44, min = -1, max = 1),
                  AD_PD = runif(44, min = -1, max = 1),
                  AD = runif(44, min = -1, max = 1))
rownames(data) <- paste0("M", 1:44)
data <- t(data)
data[,1:5]
#                  M1          M2           M3         M4          M5
# Control  0.48586439  0.81613777  0.341043832  0.4810714 -0.19630149
# PD       0.22637275 -0.61408027 -0.846040122  0.5593672  0.05330654
# AD_PD    0.41983811  0.06117967  0.004657003 -0.1992623  0.36452314
# AD      -0.03745337 -0.23319219  0.063517675  0.7082907 -0.41313420

# p值矩阵：随机创建一个逻辑型矩阵就好；
p_mat <- as.data.frame(matrix(sample(c(T,F), size = 44*4, replace = T), 4, 44))
p_mat[,1:5]
#      V1    V2    V3    V4    V5
# 1  TRUE FALSE  TRUE FALSE  TRUE
# 2 FALSE FALSE FALSE  TRUE FALSE
# 3  TRUE FALSE FALSE  TRUE  TRUE
# 4  TRUE  TRUE FALSE FALSE FALSE

##### 绘图 ---------------
# 设置颜色：
library(circlize)
library(paletteer)
col_fun <- colorRamp2(c(-1, 0, 1), c("#5296cc", "#ffffff","#c7462b"))

# colorbar的颜色：
d_palettes <- palettes_d_names
col_anno <- as.character(paletteer_d("ggsci::default_igv", n=44)) #随机选一个查看
names(col_anno) <- colnames(data)

# colorbar:
top_anno <- HeatmapAnnotation(Module = colnames(data),
                              col = list(Module = col_anno),
                              border = T,show_annotation_name = F,
                              # 去除图例：
                              show_legend = F)

# 绘图：
pdf("plots.pdf", height = 3, width = 10)
Heatmap(data,
        # 行不聚类：
        cluster_rows = F,
        # 列聚类树高度：
        column_dend_height = unit(35, "mm"),
        # 设置颜色：
        col = col_fun,
        # 调整热图格子的边框颜色和粗细：
        rect_gp = gpar(col = "black", lwd = 1),
        # 行名放左边：
        row_names_side = "left",
        # 列名放上边：
        column_names_side = "top",
        # colorbar:
        top_annotation = top_anno,
        # 加星号：
        cell_fun = function(j, i, x, y, width, height, fill) {
          if (p_mat[i,j]) {
            grid.text(sprintf("*"), x, y, gp = gpar(fontsize = 10))
          } else {
            grid.text(sprintf(""), x, y, gp = gpar(fontsize = 10))
          }
        },
        # 修改图例标题：
        heatmap_legend_param = list(title = "Correlation\n(BiCor)"))
dev.off()







