library(xlsx)
library(ComplexHeatmap)
library(tidyverse)
library(ggplot2)
library(circlize)
library(patchwork)
library(ggplotify)

# 读取文章附件数据：
data <- read.xlsx("41467_2022_31780_MOESM9_ESM.xlsx", sheetIndex = 1)
data <- data[-c(1:2), ]
colnames(data) <- data[1,]
data <- data[-1,]

# 数据预处理：
data_mat <- as.data.frame(table(data$Gene, data$`Abbreviation of Tumor Type`)) %>% 
  pivot_wider(names_from = Var2, values_from = Freq) %>% 
  column_to_rownames("Var1")

data_mat <- data_mat[,order(colSums(data_mat), decreasing = T)]
data_mat <- data_mat[order(rowSums(data_mat), decreasing = T),]
data_mat2 <- as.matrix(data_mat)
data_mat2[which(data_mat2 == 0)] <- NA

# 基础热图：
Heatmap(data_mat2,
        na_col = "white",
        # 去掉行列聚类：
        cluster_rows = F,
        cluster_columns = F)


# 修改颜色+添加文字和描边
col_fun = colorRamp2(c(0, 5, 10, 15), c("#b4d9e5", "#91a1cf", "#716bbf","#5239a3"))

p1 <- Heatmap(data_mat2,
        col = col_fun,
        na_col = "white",
        # 去掉行列聚类：
        cluster_rows = F,
        cluster_columns = F,
        row_names_side = "left",
        # 图例
        heatmap_legend_param = list(
          title = "Frequency(%)", 
          title_position = "leftcenter",
          legend_direction = "horizontal"
        ),
        # 行名和列名：
        row_names_gp = gpar(fontsize = 10, font = 3),
        column_names_gp = gpar(fontsize = 10, font = 3),
        # 添加文字注释：
        cell_fun = function(j, i, x, y, width, height, fill) {
          if (!is.na(data_mat2[i,j])) {
            grid.text(sprintf("%1.f", data_mat2[i, j]), x, y, 
                      gp = gpar(fontsize = 10, col = "#df9536"))
            grid.rect(x, y, width, height,
                      gp = gpar(col = "grey", fill = NA, lwd = 0.8))
          }
        })

pdf("Heatmap.pdf", height = 8, width = 8)
draw(p1, heatmap_legend_side = "bottom")
dev.off()


# 添加左侧堆积柱状图:
data_mat3 <- as_tibble(data_mat/rowSums(data_mat)) %>% 
  pivot_longer(cols = everything(), names_to = "CancerType",
               values_to = "value")
data_mat3$Gene <- factor(rep(rownames(data_mat), each = 21), 
                            levels = rev(rownames(data_mat)))

p2 <- ggplot(data_mat3)+
  geom_bar(aes(x = Gene, y = value, fill = CancerType), 
           position = "stack", stat = "identity")+
  scale_y_continuous(labels = seq(0,100,25),position = "right")+
  ggsci::scale_fill_igv()+
  ylab("Percentage(%)")+
  theme_bw()+
  theme(panel.grid = element_blank(), 
        axis.title.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        axis.title.x = element_text(face = "bold"),
        legend.position = "bottom",
        legend.key.size = unit(0.3, 'cm'),
        legend.title=element_text(face="bold")
        )+
  labs(fill = "Tumor Type")+
  guides(fill = guide_legend(title.position = "top",
                             title.hjust = 0.5, ncol = 2, 
                             byrow = TRUE))+
  coord_flip()

p2

ggsave("Stack_Barplot.pdf", height = 8, width = 1.5)
