library(tidyverse)

# 构造虚拟数据 -- 无实际意义
data <- data.frame(LUAD = sample(x = 1:100, size = 12),
                   STAD = sample(x = 1:100, size = 12),
                   SKCM = sample(x = 1:100, size = 12))
# data$x <- rep(c("WT", "LOH", "Loss"), each = 4)
data$x <- rep(c(1:3), each = 4)
data$group <- rep(c(LETTERS[1:4]), 3)

# 长宽数据转换：
data_long <- data %>% 
  pivot_longer(cols = !c(x, group),
               names_to = "group2",
               values_to = "values") #%>% 
  #mutate(x = factor(x, levels = c("WT", "LOH", "Loss")))

head(data_long)
# # A tibble: 6 × 4
# x     group group2 values
# <chr> <chr> <chr>   <int>
# 1 WT    A     LUAD       20
# 2 WT    A     STAD       25
# 3 WT    A     SKCM       47
# 4 WT    B     LUAD       25
# 5 WT    B     STAD       59
# 6 WT    B     SKCM       89

# 绘图：
# 先画一张：
ggplot(data_long[which(data_long$group2 == "LUAD"),]) +
  geom_area(aes(x, values, fill = group),
            position = "fill") +
  geom_vline(xintercept = 2, color = "white", size = 0.2)+
  scale_fill_manual(values = rev(c("#4552a9", "#9cd6ed", 
                                   "#faea6b", "#f2791e")))+
  scale_x_continuous(expand = c(0, 0),
                     breaks = c(1:3), 
                     labels = c("WT", "LOH", "Loss")) +
  scale_y_continuous(expand = c(0, 0)) +
  xlab("")+
  ylab("")+
  ggtitle("LUAD")+
  theme(plot.title = element_text(hjust = 0.5),
        axis.ticks.x = element_blank(), 
        axis.text.x = element_text(angle = 30, hjust = 0.7),
        legend.position = "none")

ggsave("plot1.pdf", height = 6, width = 3)


# 循环绘图：
p_list <- list()

for (i in 1:length(unique(data_long$group2))) {
  if (i == 1) {
    p_list[[i]] <- ggplot(data_long[which(data_long$group2 == unique(data_long$group2)[i]),]) +
      geom_area(aes(x, values, fill = group),
                position = "fill") +
      geom_vline(xintercept = 2, color = "white", size = 0.2)+
      scale_fill_manual(values = rev(c("#4552a9", "#9cd6ed", 
                                       "#faea6b", "#f2791e")))+
      scale_x_continuous(expand = c(0, 0),
                         breaks = c(1:3), 
                         labels = c("WT", "LOH", "Loss")) +
      scale_y_continuous(expand = c(0, 0)) +
      xlab("")+
      ylab("")+
      ggtitle(unique(data_long$group2)[i])+
      theme(plot.title = element_text(hjust = 0.5),
            axis.ticks.x = element_blank(), 
            axis.text.x = element_text(angle = 30, hjust = 0.7),
            legend.position = "none")
  } else {
    p_list[[i]] <- ggplot(data_long[which(data_long$group2 == unique(data_long$group2)[i]),]) +
      geom_area(aes(x, values, fill = group),
                position = "fill") +
      geom_vline(xintercept = 2, color = "white", size = 0.2)+
      scale_fill_manual(values = rev(c("#4552a9", "#9cd6ed", 
                                       "#faea6b", "#f2791e")))+
      scale_x_continuous(expand = c(0, 0),
                         breaks = c(1:3), 
                         labels = c("WT", "LOH", "Loss")) +
      scale_y_continuous(expand = c(0, 0)) +
      xlab("")+
      ylab("")+
      ggtitle(unique(data_long$group2)[i])+
      theme(plot.title = element_text(hjust = 0.5),
            axis.ticks = element_blank(), 
            axis.text.y = element_blank(), 
            axis.text.x = element_text(angle = 30, hjust = 0.7),
            legend.position = "none")
  }
}

# 拼图：
library(cowplot)

plot_grid(plotlist = p_list, ncol = 3, rel_widths = c(1.15,1,1))

ggsave("plot2.pdf", height = 6, width = 8)

