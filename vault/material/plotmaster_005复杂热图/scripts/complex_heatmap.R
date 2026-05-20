LU_matrix <- matrix(runif(200, 0, 0.5), nrow = 10, ncol = 20)
RD_matrix <- matrix(runif(340, -0.5, 0), nrow = 17, ncol = 20)
RU_matrix <- matrix(runif(20, -0.5, 0), nrow = 10, ncol = 2)
LD_matrix <- matrix(runif(34, 0, 0.5), nrow = 17, ncol = 2)

data <- rbind(cbind(LU_matrix, RU_matrix), cbind(RD_matrix, LD_matrix))
# data <- round(data, 1)
names <- read.table("rownames.txt")

#rownames(data) <- names[1:27,1]
#colnames(data) <- names[27:48,1]

library(ComplexHeatmap)
# 基础绘图：
Heatmap(data)

# 设置颜色：
library(circlize)
col_fun <- colorRamp2(c(-0.5, -0.1,0.1, 0.5), c("#5296cc", "#cad5f9", "#fdedf6","#f064af"))

Heatmap(data, 
        # 设置颜色：
        col = col_fun,
        # 调整热图格子的边框颜色和粗细：
        rect_gp = gpar(col = "white", lwd = 1),
        # 调整聚类树的高度：
        column_dend_height = unit(2, "cm"), 
        row_dend_width = unit(2, "cm"),
        cell_fun = function(j, i, x, y, width, height, fill) {
          grid.text(sprintf("%.1f", data[i, j]), x, y, gp = gpar(fontsize = 5))})


# 还需要一个p值矩阵：
p_data <- matrix(runif(27*22, 0, 0.1), nrow = 27, ncol = 22)

Heatmap(data, 
        # 设置颜色：
        col = col_fun,
        # 调整热图格子的边框颜色和粗细：
        rect_gp = gpar(col = "white", lwd = 1),
        # 调整聚类树的高度：
        column_dend_height = unit(2, "cm"), 
        row_dend_width = unit(2, "cm"),
        cell_fun = function(j, i, x, y, width, height, fill) {
          if (p_data[i,j] < 0.01) {
            grid.text(sprintf("*", data[i, j]), x, y, gp = gpar(fontsize = 6))
          } else if (p_data[i,j]<0.05) {
            grid.text(sprintf("+", data[i, j]), x, y, gp = gpar(fontsize = 6))
          } else {
            grid.text(sprintf("", data[i, j]), x, y, gp = gpar(fontsize = 6))
          }
        })


T_data <- matrix(runif(27*22, 0, 0.1), nrow = 27, ncol = 22)
T_data <- T_data > 0.05


# 加上行名和列名
rownames(data) <- names[1:27,1]
colnames(data) <- names[27:48,1]

# 最终热图效果：
# row_ha <- rowAnnotation(foo = runif(27), bar2 = anno_barplot(runif(27)))

pdf("Heatmap.pdf", height = 6, width = 7)
Heatmap(data, 
        # 设置颜色：
        col = col_fun,
        # 调整热图格子的边框颜色和粗细：
        rect_gp = gpar(col = "white", lwd = 1),
        # 调整聚类树的高度：
        column_dend_height = unit(2, "cm"), 
        row_dend_width = unit(2, "cm"),
        # 调整行标签和列标签的大小：
        row_names_gp = gpar(fontsize = 7, fontface = "italic", # 调整字体为斜体：
                            # 调整标签颜色：
                            col = c(rep("#ff339f", 10), rep("#5facee", 20))),
        column_names_gp = gpar(fontsize = 7),
        # 添加单元格中的注释：
        cell_fun = function(j, i, x, y, width, height, fill) {
          if (p_data[i,j] < 0.01) {
            grid.text(sprintf("*  ", data[i, j]), x, y, gp = gpar(fontsize = 8))
          } else if (p_data[i,j]<0.05) {
            grid.text(sprintf("+   ", data[i, j]), x, y, gp = gpar(fontsize = 6))
          } else {
            grid.text(sprintf("", data[i, j]), x, y, gp = gpar(fontsize = 6))
          }
          if (T_data[i,j]) {
            grid.text(sprintf("   #", data[i, j]), x, y, gp = gpar(fontsize = 6))
          } else {
            grid.text(sprintf("", data[i, j]), x, y, gp = gpar(fontsize = 6))
          }
        },
        # 调整图例：
        show_heatmap_legend = FALSE,
        # heatmap_legend_param = list(col_fun = col_fun, 
        #                             at = c(-0.5, 0, 0.5),
        #                             # labels = c("low", "zero", "high"),
        #                             title = "Spearman's correlation",
        #                             legend_height = unit(2, "cm"),
        #                             title_position = "topcenter",
        #                             title_gp = gpar(fontsize = 5),
        #                             labels_gp = gpar(fontsize = 5),
        #                             direction = "horizontal",
        #                             grid_height = unit(3, "mm"))
        # 聚类树排序
        column_dend_reorder = FALSE
        # right_annotation = row_ha
        )

# 图例参数：
lgd <- Legend(col_fun = col_fun, 
              at = c(-0.5, 0, 0.5),
              # labels = c("low", "zero", "high"),
              title = "Spearman's correlation",
              legend_height = unit(2, "cm"),
              title_position = "topcenter",
              title_gp = gpar(fontsize = 8),
              labels_gp = gpar(fontsize = 8),
              direction = "horizontal",
              grid_height = unit(4, "mm")
              )

# 绘制图例：
draw(lgd, x = unit(0.9, "npc"), y = unit(0.95, "npc"))

dev.off()

library(ggplot2)
# 添加柱状图：
bar_data <- as.data.frame(rowSums(data))
colnames(bar_data) <- "lncMSE"
bar_data$group <- "Pos"
bar_data$group[which(bar_data$lncMSE < 0)] <- "Neg"

library(ggplot2)
ggplot(data = bar_data)+
  geom_bar(aes(x=rev(1:27),
               y=abs(lncMSE), fill = group), stat = "identity")+
  scale_fill_manual(values = c("#ff339f","#5facee"))+
  coord_flip()+
  xlab("")+
  ylab("%lncMSE")+
  theme_classic()+
  theme(legend.position = "none",
        axis.ticks.y = element_blank(), 
        axis.text.y = element_blank(),
        axis.line.y = element_blank())+
  scale_y_continuous(breaks = c(0:6))

ggsave("barplot.pdf", height = 6, width = 2.5)

# 拼图：试了一下不能使用patchwork，因为是Heatmap不是ggplot对象：
library(patchwork)
p1+p2+plot_layout(widths = c(3,1))














