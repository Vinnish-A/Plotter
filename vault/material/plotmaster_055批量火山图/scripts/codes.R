library(readxl)
library(tidyverse)
library(ggplot2)
library(cowplot)

# 本期数据为文章附表S6：
data <- read_excel("Supplemental Excel Table.xlsx", sheet = 6)
colnames(data) <- data[1,]
# 使用fill函数填充第一列：
data <- data[-c(1, nrow(data)),] %>% fill(Pollutant)

# 数据类型转换：
data$Estimate <- as.numeric(data$Estimate)
data$`P-value` <- as.numeric(data$`P-value`)
data$FDR <- as.numeric(data$FDR)

table(data$Pollutant)
# DBP DPHP TiBP TMPP TPHP
# 101   32  221  213  308

data$Pollutant <- factor(data$Pollutant, c("TiBP","TMPP","TPHP","DBP","DPHP"))
Pollutant_names <- c("TiBP","TMPP","TPHP","DBP","DPHP")

# 由于作者提供的附件数据中FDR值只保留了两位小数，而且数值好像也经过了过滤，
# 为了使得图形更美观，师兄这里就用师兄ggVolcano包中的示例数据的logFC值和FDR值替换一下
# 无实际意义！！！
deg_data <- ggVolcano::deg_data
deg_data <- deg_data[order(deg_data$padj),]

index <- sample(100:(nrow(deg_data)-100), nrow(data))
data$Estimate <- deg_data$log2FoldChange[index]/10
data$FDR <- deg_data$padj[index]

# 新建group列：如果FDR不显著，为灰色；
data$group <- data$Assiciation
data$group[data$FDR<0.05 & data$Estimate<0] <- "Negative"
data$group[data$FDR<0.05 & data$Estimate>0] <- "Positive"
data$group[data$FDR>0.05] <- "Not significant"

# 单独绘图：
plot_data <- data %>% filter(Pollutant == Pollutant_names[1])
xlim_value <- max(abs(plot_data$Estimate*100))
ylim_value <- max(-log10(plot_data$FDR))
p1 <- ggplot(plot_data)+
  geom_vline(xintercept = 0, linetype = 3)+
  geom_hline(yintercept = -log10(0.05), linetype = 3)+
  geom_point(aes(Estimate*100, -log10(FDR), size = abs(Estimate),
                 fill = group), shape = 21, color = "white")+
  annotate("text", x = -xlim_value*3/4, y = ylim_value*7/8, color = "#50b0d4",
           label = paste0("Negative:", sum(plot_data$group == "Negative")))+
  annotate("text", x = xlim_value*3/4, y = ylim_value*7/8, color = "#d14d49",
           label = paste0("Positive:", sum(plot_data$group == "Positive")))+
  xlab("Percentage change(%)")+
  scale_fill_manual(values = c("Negative" = "#50b0d4",
                               "Positive" = "#d14d49",
                               "Not significant" = "#a8b1ae"))+
  scale_size_continuous(range = c(1, 3))+
  xlim(-xlim_value, xlim_value)+
  theme_classic()+
  theme(legend.position = "none",
        plot.title = element_text(hjust = 0.5))


# 由于标题有个背景，ggplot2不太好加，分面的话又会导致坐标轴不好加，
# 这个办法也是权宜之计，属实是有点杀鸡用牛刀了，可以在AI中轻松绘制；
title_plot <- ggplot() +
  theme_void() +
  xlim(-0.108, 0.092)+
  annotation_custom(grob = rectGrob(gp = gpar(fill = "#2495a4", col = NA)),
                    xmin = -0.1, xmax = 0.1, ymin = -0.5, ymax = 1.5)+
  annotate("text", x = 0, y = 0.5, label = Pollutant_names[1],
           size = 5, hjust = 0.5, color = "white")

pdf("plot.pdf", height = 4, width = 5)
plot_grid(title_plot, p1, ncol = 1, rel_heights = c(1, 10))
dev.off()



############ 批量绘图 -------------
plot_list <- list()
for (i in 1:length(Pollutant_names)) {
  plot_data <- data %>% filter(Pollutant == Pollutant_names[i])
  xlim_value <- max(abs(plot_data$Estimate*100))
  ylim_value <- max(-log10(plot_data$FDR))
  if (i == 1) {
    p1 <- ggplot(plot_data)+
      geom_vline(xintercept = 0, linetype = 3)+
      geom_hline(yintercept = -log10(0.05), linetype = 3)+
      geom_point(aes(Estimate*100, -log10(FDR), size = abs(Estimate),
                     fill = group), shape = 21, color = "white")+
      annotate("text", x = -xlim_value*2/3, y = ylim_value*7/8, color = "#50b0d4",
               label = paste0("Negative:", sum(plot_data$group == "Negative")))+
      annotate("text", x = xlim_value*2/3, y = ylim_value*7/8, color = "#d14d49",
               label = paste0("Positive:", sum(plot_data$group == "Positive")))+
      xlab("")+
      scale_fill_manual(values = c("Negative" = "#50b0d4",
                                   "Positive" = "#d14d49",
                                   "Not significant" = "#a8b1ae"))+
      scale_size_continuous(range = c(1, 3))+
      xlim(-xlim_value, xlim_value)+
      theme_classic()+
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5))


    # 由于标题有个背景，ggplot2不太好加，分面的话又会导致坐标轴不好加，
    # 这个办法也是权宜之计，属实是有点杀鸡用牛刀了，可以在AI中轻松绘制；
    title_plot <- ggplot() +
      theme_void() +
      xlim(-0.12, 0.08)+
      annotation_custom(grob = rectGrob(gp = gpar(fill = "#2495a4", col = NA)),
                        xmin = -0.1, xmax = 0.1, ymin = -0.5, ymax = 1.5)+
      annotate("text", x = 0, y = 0.5, label = Pollutant_names[i],
               size = 5, hjust = 0.5, color = "white")
  } else {
    p1 <- ggplot(plot_data)+
      geom_vline(xintercept = 0, linetype = 3)+
      geom_hline(yintercept = -log10(0.05), linetype = 3)+
      geom_point(aes(Estimate*100, -log10(FDR), size = abs(Estimate),
                     fill = group), shape = 21, color = "white")+
      annotate("text", x = -xlim_value*2/3, y = ylim_value*7/8, color = "#50b0d4",
               label = paste0("Negative:", sum(plot_data$group == "Negative")))+
      annotate("text", x = xlim_value*2/3, y = ylim_value*7/8, color = "#d14d49",
               label = paste0("Positive:", sum(plot_data$group == "Positive")))+
      xlab("")+
      ylab("")+
      scale_fill_manual(values = c("Negative" = "#50b0d4",
                                   "Positive" = "#d14d49",
                                   "Not significant" = "#a8b1ae"))+
      scale_size_continuous(range = c(1, 3))+
      xlim(-xlim_value, xlim_value)+
      theme_classic()+
      theme(legend.position = "none",
            plot.title = element_text(hjust = 0.5))


    # 由于标题有个背景，ggplot2不太好加，分面的话又会导致坐标轴不好加，
    # 这个办法也是权宜之计，属实是有点杀鸡用牛刀了，可以在AI中轻松绘制；
    title_plot <- ggplot() +
      theme_void() +
      xlim(-0.12, 0.08)+
      annotation_custom(grob = rectGrob(gp = gpar(fill = "#2495a4", col = NA)),
                        xmin = -0.1, xmax = 0.1, ymin = -0.5, ymax = 1.5)+
      annotate("text", x = 0, y = 0.5, label = Pollutant_names[i],
               size = 5, hjust = 0.5, color = "white")
  }

  plot_list[[i]] <- plot_grid(title_plot, p1, ncol = 1, rel_heights = c(1, 10))
}

pdf("plot_all.pdf", height = 3, width = 15)
plot_grid(plotlist = plot_list, nrow = 1, rel_widths = c(1.1, 1, 1, 1, 1))
dev.off()
