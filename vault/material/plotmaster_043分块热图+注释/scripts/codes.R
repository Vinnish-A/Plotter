library(tidyverse)
library(ComplexHeatmap)

############# 构造数据 ---------------
data <- data.frame(
  # 第一组：
  c1 = runif(45, 0, 5),
  c2 = runif(45, 0, 5),
  c3 = runif(45, 0, 5),
  # 第二组：
  c4 = runif(45, 0, 10),
  c5 = runif(45, 0, 10),
  c6 = runif(45, 0, 10),
  # 第三组：
  c7 = runif(45, 0, 10),
  c8 = runif(45, 0, 10),
  c9 = runif(45, 0, 10))

rownames(data) <- paste0("BnaA", sample(45))

# 行分块信息：
group_row1 <- rep(LETTERS[1:16], c(4, 2, 1, 5, 3,
                                   4, 3, 3, 2, 3,
                                   4, 2, 1, 4, 3, 1))
# 灰色行注释信息:
group_row2 <- rep(LETTERS[1:6], c(7, 8, 7, 8, 7, 8))

# 三角形注释信息：
group_row3 <- as.character(sample(c(0, 1, 2), 45,
                                  prob = c(0.6, 0.3, 0.1),
                                  replace = T))

# 列分块信息：
group_col <- factor(rep(c("LWC", "MWC", "HWC"), each = 3),
                    levels = c("LWC", "MWC", "HWC"))


############## 绘图 ----------------
# 颜色：
library(circlize)
col_fun = colorRamp2(c(0, 2, 5, 7, 10), c("#2b3a7c", "#cae0ed", "#faf6be",
                                        "#e58e5d", "#792119"))

# 顶部注释：
top_Anno <- HeatmapAnnotation(group = group_col,
                              # colorbar的大小：
                              simple_anno_size = unit(0.1, "cm"),
                              # colorbar的图例和名称：
                              show_legend = F,
                              show_annotation_name = F,
                              # 颜色：
                              col = list(group = c("LWC" = "#4f9d88",
                                                   "MWC" = "#415586",
                                                   "HWC" = "#696969")))
# 右侧注释：
graphics = list(
  "1" = function(x, y, w, h) {
    grid.points(x, y, gp = gpar(col = "#d23829"), pch = 17,size = unit(5, "pt"))
  },
  "0" = function(x, y, w, h) {
    grid.points(x, y, gp = gpar(col = "#d23829"), pch = 17, size = unit(0, "pt"))
  },
  "2" = function(x, y, w, h) {
    grid.points(x, y, gp = gpar(fill = "#57a5da", col = NA), pch = 25,size = unit(5, "pt"))
  }
)

row2_col <- rep("#bdbdbd", 45)
names(row2_col) <- group_row2

right_Anno <- rowAnnotation(row1 = anno_customize(group_row3[1:25],
                                                  graphics = graphics,
                                                  border = FALSE),
                            row2 = group_row2[1:25],
                            simple_anno_size = unit(0.1, "cm"),
                            # 颜色：
                            col = list(row2 = row2_col[1:25]),
                            show_annotation_name = F,
                            show_legend = F
                            )

## 左边热图：
p1 <- Heatmap(as.matrix(data[1:25, ]),
        # 取消聚类：
        cluster_rows = F,
        cluster_columns = F,
        # 颜色：
        col = col_fun,
        # 行标签位置：
        row_names_side = "left",
        row_names_gp = gpar(fontsize = 5, fontface = "italic"),
        # 去掉列标签：
        show_column_names = F,
        # 热图方块描边：
        rect_gp = gpar(col = "white", lwd = 1),
        # 分块：
        row_split = group_row1[1:25],
        row_title = NULL,
        column_split = group_col,
        column_title_gp = gpar(fontsize = 7),
        # 列注释：
        top_annotation = top_Anno,
        # 右侧行注释：
        right_annotation = right_Anno,
        # 去掉图例：
        show_heatmap_legend = F)

pdf("plot1.pdf", height = 3, width = 3)
p1
dev.off()
########### 右侧图 -------------------
# 颜色：
right_Anno <- rowAnnotation(row1 = anno_customize(group_row3[26:45],
                                                  graphics = graphics,
                                                  border = FALSE),
                            row2 = group_row2[26:45],
                            simple_anno_size = unit(0.1, "cm"),
                            # 颜色：
                            col = list(row2 = row2_col[26:45]),
                            show_annotation_name = F,
                            show_legend = F
)

## 右边热图：
p2 <- Heatmap(as.matrix(data[26:45, ]),
        # 取消聚类：
        cluster_rows = F,
        cluster_columns = F,
        # 颜色：
        col = col_fun,
        # 行标签位置：
        row_names_side = "left",
        row_names_gp = gpar(fontsize = 5, fontface = "italic"),
        # 去掉列标签：
        show_column_names = F,
        # 热图方块描边：
        rect_gp = gpar(col = "white", lwd = 1),
        # 分块：
        row_split = group_row1[26:45],
        row_title = NULL,
        column_split = group_col,
        column_title_gp = gpar(fontsize = 7),
        # 列注释：
        top_annotation = top_Anno,
        # 右侧行注释：
        right_annotation = right_Anno,
        # 去掉图例：
        heatmap_legend_param = list(
          title = "Log2(FPKM + 1)",
          at = seq(0, 10, 2),
          direction = "horizontal",
          title_position = "leftcenter",
          title_gp = gpar(fontface = "plain", fontsize = 8),
          labels_gp = gpar(fontsize = 5)
        ))

pdf("plot2.pdf", height = 3, width = 3)
draw(p2, heatmap_legend_side = "bottom")
dev.off()











