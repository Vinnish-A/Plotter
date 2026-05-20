library(tidyverse)

# 构造数据：
# size_fractions:
Size_fractions <- as.data.frame(matrix(NA, nrow = 30, ncol = 5))
for (i in 1:5) {
  Size_fractions[,i] <- c(runif(10, min = 2, max = 60),
                         runif(10, min = 1, max = 30),
                         runif(10, min = 0, max = 5))
}
colnames(Size_fractions) <- c("<0.2","0.2-0.8","0.2-3","0.8-20",">0.2")

# Latitudes
Latitudes <- as.data.frame(matrix(NA, nrow = 30, ncol = 3))

for (i in 1:3) {
  Latitudes[,i] <- c(runif(10, min = 40, max = 80),
                     runif(10, min = 5, max = 60),
                     runif(10, min = 0, max = 70))
}

colnames(Latitudes) <- c("<30", "30-60", ">60")

# Depth layers
Depth_layers <- as.data.frame(matrix(NA, nrow = 30, ncol = 3))

for (i in 1:3) {
  Depth_layers[,i] <- c(runif(10, min = 40, max = 80),
                     runif(10, min = 5, max = 40),
                     runif(10, min = 0, max = 60))
}

colnames(Depth_layers) <- c("EPI", "MES", "BAT")

# 合并：
data <- cbind(Size_fractions, Latitudes, Depth_layers)
data$group <- factor(rep(c("OMD", "GEM", "GORG"), each = 10),
                     levels = c("OMD", "GEM", "GORG"))

# 转长数据：
data_long <- pivot_longer(data, cols = !group, 
                          names_to = "x", values_to = "y")
data_long$group2 <- factor(rep(rep(c("Size fraction(um)", "Latitudes", "Depth layers"),
                        c(5, 3, 3)), 30), levels = c("Size fraction(um)", "Latitudes", "Depth layers"))
data_long$x <- factor(data_long$x, levels = unique(data_long$x))


# 画图：
p1 <- ggplot(data_long)+
  geom_boxplot(aes(x, y, fill = group, color = group), alpha = 0.5, outlier.shape = NA)+
  facet_grid(.~group2, scales="free_x", space = "free_x")+
  scale_color_manual(name = "", values = c("#5aadd0", "#a9dcb6", "#af7aa1"))+
  scale_fill_manual(name = "", values = c("#5aadd0", "#a9dcb6", "#af7aa1"))+
  xlab("")+
  ylab("Reads mapped(%)")+
  scale_y_continuous(breaks = seq(0,80,20), limits = c(0, 80),expand = c(0,0))+
  # 主题调整：
  theme_classic()+
  theme(strip.background = element_blank(),
        strip.text.x = element_text(size = 12),
        axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        legend.position = "bottom")

p1

ggsave("plot1.pdf", height = 3.5, width = 8)

rect_data <- data.frame(x = c(1:5, c(6:8)+0.2, c(9:11)+0.4),
                        y = unique(data_long$x))

p2 <- ggplot(rect_data,aes(x, y = 1))+
  geom_tile(aes(fill=y),color="white",linewidth=1)+
  scale_x_discrete("",expand = c(0,0))+ #不显示横纵轴的label文本；画板不延长
  scale_y_discrete("",expand = c(0,0))+
  scale_fill_manual(values = c("#fa7f5e", "#f2605c", "#dd4968", "#c43c75", "#a8327d",
                               "#d38c39", "#cac5bf", "#4f69b1", 
                               "#dbdb5f", "#509f9b", "#1e497f"))+
  theme(
    panel.background = element_blank(),
    # 去掉X轴的刻度标签:
    axis.text.x = element_blank(),
    axis.text.y.left = element_text(size = 12), #修改坐标轴文本大小
    axis.ticks = element_blank(), #不显示坐标轴刻度
    legend.title = element_blank(), #不显示图例title
    legend.position = "none"
  )+
  geom_text(aes(label=unique(data_long$x)), angle = 90, color = "white")
p2
ggsave("plot2.pdf", height = 1.5, width = 8)

library(patchwork)

p2/p1+plot_layout(heights = c(2,5))

ggsave("plots.pdf", height = 5, width = 8)




