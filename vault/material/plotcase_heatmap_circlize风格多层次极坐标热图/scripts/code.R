library(circlize)
library(tidyverse)
library(RColorBrewer)
library(readxl)
library(ComplexHeatmap)

sessionInfo()

df <- read_excel("41591_2025_3891_MOESM5_ESM.xlsx", sheet = 1) %>% 
  select(4,2,3,5) %>% 
  arrange(super_class_metabolon) %>% 
  mutate(metabolite_name = str_extract(metabolite_name, "^[^/]+"))
# 构建矩阵
tmp_circle_all_mat <- df %>% column_to_rownames(var="metabolite_name")
split_super_class <- df$super_class_metabolon   

circos.clear()
par(mar = rep(0, 4))
circos.par("canvas.xlim" = c(-1,1),"canvas.ylim" = c(-1,1))

circos.heatmap.initialize(tmp_circle_all_mat,
                          split = split_super_class, cluster = FALSE)

# 数据转换
tmp_circle_all_mat_cv <- tmp_circle_all_mat %>% select(2) %>% 
  mutate(cv = log10(cv))
mean_abundance <- tmp_circle_all_mat %>% select(1) %>% 
  mutate(mean_abundance = log10(mean_abundance))
# 颜色函数
col_fun1 <- colorRamp2(c(min(mean_abundance),
                         max(mean_abundance)),c("white", "#6497b1"))
col_fun2 <- colorRamp2(c(min(tmp_circle_all_mat_cv),
                         max(tmp_circle_all_mat_cv)), c("white", "darkgray"))
# 第一层 (CV)
circos.heatmap(tmp_circle_all_mat_cv,
               col = col_fun2,
               split = split_super_class,
               cluster = FALSE,
               rownames.side = "outside",
               rownames.cex = 0.3,track.height = 0.1,
               bg.border="black",bg.lwd = 1,bg.lty = 1)
# 第二层 (mean abundance)
circos.heatmap(mean_abundance,col = col_fun1,
               split = split_super_class,
               cluster = FALSE,
               rownames.side = "none",
               track.height = 0.1,
               bg.border="black",bg.lwd = 1,bg.lty = 1)
# 第三层 (分类条)
mat_class <- matrix(df$super_class_metabolon,ncol = 1)
rownames(mat_class) <- rownames(tmp_circle_all_mat)
class_levels <- unique(df$super_class_metabolon)
classcol <- setNames(RColorBrewer::brewer.pal(length(class_levels), "Set3"),
                     class_levels)

circos.heatmap(mat_class,col = classcol,
               cluster = FALSE,track.height = 0.02)

circos.clear()

# 绘制图例
lgd_mean_abundance <- Legend(
  title = expression(bold(paste("log"[10],"(mean abundance, %)",sep=""))),
  title_gp = gpar(fontsize = 10),
  direction = "horizontal",col_fun = col_fun1)

lgd_cv <- Legend(
  title = expression(bold(paste("log"[10],"(coefficient of variation)",sep=""))),
  title_gp = gpar(fontsize = 10),
  direction = "horizontal",col_fun = col_fun2)

lgd_super_class <- Legend(
  title = "Superclass of metabolites",
  title_gp = gpar(fontsize = 10, fontface = "bold"),
  at = names(classcol),legend_gp = gpar(fill = classcol))

lgd_list = packLegend(lgd_mean_abundance, lgd_cv,
                      lgd_super_class,
                      max_height = unit(12, "cm"))
draw(lgd_list)