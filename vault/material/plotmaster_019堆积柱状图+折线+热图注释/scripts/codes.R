library(ggplot2)
library(tidyverse)
library(ComplexHeatmap)
library(RColorBrewer)
library(patchwork)

############## 热图数据构建 + 图形绘制 ################## 
# 构建模拟数据:
# 上方热图注释：
x = factor(c(paste0("P", 1:17), 
             paste0("M", 1:10), 
             paste0("C", 1:3)), 
             levels = c(paste0("P", 1:17), 
                        paste0("M", 1:10), 
                        paste0("C", 1:3)))

heatmap_data <- data.frame(
  Data_source = sample(c("GSE131907", "GSE123904"), 30, replace = T),
  Sample_Origins = rep(c("Primary", "Distant Metastasis", "Chemotherapy"), c(15,12,3)),
  Smoking = sample(c("Current Smoker", "Former Smoker", "Never Smoker"), 30, replace = T),
  EGFR = sample(c("EGFR Mutation", "WT"), 30, replace = T),
  Stages = sample(paste0("Stage", 1:4), 30, replace = T)
)

rownames(heatmap_data) <- x

cols <- list(Data_source = c("#ff8969", "#e9cd50"),
             Sample_Origins = c("#0e9cc4", "#f3734e", "#c05a9c"),
             Smoking = c("#bed4ad", "#bdd3ac", "#96c18c"), 
             EGFR = c("#f7d4b5","#fcf5dd"),
             Stages = c("#feeff4", "#f5cedc", "#f7afcc", "#ec75a7")
)

cols_vec <- unlist(cols)

names(cols_vec) <- c("GSE131907", "GSE123904",
                     "Primary", "Distant Metastasis", "Chemotherapy",
                     "Current Smoker", "Former Smoker", "Never Smoker",
                     "EGFR Mutation", "WT",
                     paste0("Stage", 1:4))

# 绘制上方热图：
p <- Heatmap(t(heatmap_data),
             col = cols_vec,
             row_names_side = "left",
             row_names_gp = gpar(fontsize = 5),
             rect_gp = gpar(col = "white", lwd = 1),
             show_column_names = F,
             show_heatmap_legend = F)

p

# 自定义图例：
k = 1
lgd = list()
for(i in 1:ncol(heatmap_data)){
  un = sort(unique(heatmap_data[,i]))
  ti = colnames(heatmap_data)[i]
  lgd[[i]] = Legend(seq(0, 1, length.out = length(un)), labels = un,
                    title = ti, legend_gp = gpar(fill = cols_vec[un]))
  k = k + length(un)
}

# 把各个图例合并在一起
pd = packLegend(list = lgd, 
                direction = "vertical", 
                column_gap = unit(5, "mm"), 
                row_gap = unit(1, "cm"))

pdf("legend.pdf", height = 6, width = 1.5)
draw(pd)
dev.off()


############## 折线图数据构建 + 图形绘制 ################## 
# 折线图数据：
line_data <- data.frame(x = factor(c(paste0("P", 1:17), 
                                     paste0("M", 1:10), 
                                     paste0("C", 1:3)), 
                              levels = c(paste0("P", 1:17), 
                                         paste0("M", 1:10), 
                                         paste0("C", 1:3))),
                        value = c(sort(sample(1:10, 18, replace = T)),
                                  sort(sample(4:12, 9, replace = T)),
                                  sort(sample(6:10, 3, replace = T))
                                  ))

# 折线图：
p2 <- ggplot(line_data, aes(x, value))+
  geom_point(size = 2)+
  geom_line(size = 1, group = 1)+
  scale_y_continuous(breaks = seq(0, 12, 2))+
  ylab("log2(Malignant Cell Number)")+
  theme_classic()+
  theme(panel.grid = element_blank(),
        axis.line.x = element_blank(),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.x = element_blank(),
        axis.line.y = element_line(size = 1),
        axis.ticks.y = element_line(size = 1))


############## 堆积柱状图数据构建 + 图形绘制 ################## 
# 堆积柱状图数据：
bar_data <- data.frame()

for (i in 1:30) {
  cell_category <- sample(3:6, 1)
  bar_data_tmp <- data.frame(
    x = rep(x[i], cell_category),
    values = sample(20:100, cell_category),
    group = paste0("group", 1:cell_category))
  bar_data_tmp$proportion <- bar_data_tmp$values/sum(bar_data_tmp$values)
  bar_data <- rbind(bar_data, bar_data_tmp)
}

# 堆积柱状图:
p3 <- ggplot(bar_data)+
  geom_bar(aes(x, proportion*100, fill = group),
           color = "white", width = 1, size = 1,
           stat = "identity", position = "stack")+
  scale_fill_brewer(palette = "Set3")+
  theme_classic()+
  ylab("Cell Proportion(%)")+
  theme(panel.grid = element_blank(),
        legend.position = "none",
        axis.line.x = element_blank(),
        axis.ticks.x = element_blank(),
        axis.title.x = element_blank(),
        axis.line.y = element_line(size = 1),
        axis.ticks.y = element_line(size = 1))

pdf("plot.pdf", height = 6, width = 7)
as.ggplot(p)/p2/p3
dev.off()

# AI拼图+调整
