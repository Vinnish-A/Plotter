###############################################
library(ggplot2)
library(latex2exp)
library(ggrepel)

# 读取数据：
# 第一个数据为差异分析的结果数据：包含gene的log2FC值和pvalue；
data <- read.csv("DEG.csv", row.names = 1)
# 第二个数据为需要展示在火山图的通路中包含的gene；
term_data <- read.csv("term_data.csv")

# 去除缺失值：
data <- na.omit(data)
# 去除重复基因：
data <- data[!duplicated(data$row),]
# 添加GO一列：
data$GO_term <- "others"
term_data <- term_data[term_data$Gene.names %in% data$row,]
data[term_data$Gene.names,]$GO_term <- term_data$term

# 计算上调下调数目：
Down_num <- length(which(data$padj < 0.05 & data$log2FoldChange < 0))
Up_num <- length(which(data$padj < 0.05 & data$log2FoldChange > 0))

# 设定原始散点颜色：
color <- rep("#999999",nrow(data))

# 选取p值最显著的25个加上标签(按照log2FC的绝对值排序)：
data$label <- rep(NA,nrow(data))
data$label[order(abs(data$log2FoldChange), decreasing = T)[1:25]] <- data$row[order(abs(data$log2FoldChange), decreasing = T)[1:25]]


ggplot(data[which(data$GO_term!="others"),],
       aes(log2FoldChange,-log10(padj),fill = GO_term))+ 
  geom_point(data=data[which(data$GO_term=="others"),],
             aes(log2FoldChange,-log10(padj)),
             size = 0.5,color="#999999") + 
  # 彩色散点：
  geom_point(size = 3, shape=21, color="black") + 
  scale_fill_manual(values=c(dendritic="#49c2c6", "ion transport."="#fbcbcc", 
                             metabolic="#eef0ac",myelin="#b1daa7",
                             synaptic="#d0d0a0")) + 
  geom_vline(xintercept = 0, linetype ="longdash") +
  geom_hline(yintercept = -log10(0.05), linetype ="longdash") + 
  labs(x = TeX("$Log_2 \\textit{FC}$"), 
       y = TeX("$-Log_{10} \\textit{FDR} $"))+
  theme(title = element_text(size = 15), text = element_text(size = 15)) + 
  theme_bw() + 
  theme(panel.grid.major=element_blank(),
        panel.grid.minor=element_blank())+
  theme(legend.position = c(0.01, 0.99),
        legend.justification = c(0, 1),
        # 图例大框颜色：
        legend.background = element_rect(
          fill = "#fefde2", # 填充色
          colour = "black", # 框线色
          # 线条宽度
          size = 0.2),
        # 图例符号颜色：
        legend.key = element_rect(
          # color = "red", # 框线色
          fill = "#fefde2"),
        # 调整图例大小：
        legend.key.size = unit(12, "pt"),
        legend.title = element_blank())+
  # 添加注释：
  annotate("text", label = "bolditalic(Down)", parse = TRUE, 
           x = -2.5, y = 25, size = 4, colour = "black")+
  annotate("text", label = "bolditalic(Up)", parse = TRUE, 
           x = 1.5, y = 25, size = 4, colour = "black")+
  annotate("text", label = Down_num, parse = TRUE, 
           x = -2.5, y = 24, size = 3, colour = "black")+
  annotate("text", label = Up_num, parse = TRUE, 
           x = 1.5, y = 24, size = 3, colour = "black")+
  # 添加gene标签：部分标签没有显示是因为重叠，可以修改max.overlaps值；
  geom_text_repel(aes(label = label),size=3,max.overlaps = 100)

ggsave("vocanol_Plot.pdf",height = 5,width = 6)


