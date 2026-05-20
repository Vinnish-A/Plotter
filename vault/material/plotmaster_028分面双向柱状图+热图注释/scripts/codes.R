library(tidyverse)
library(patchwork)

# 构造模拟数据：
Virome <- runif(61, 0, 0.2)
Bacteriome <- runif(61, 0, 1)

group <- factor(rep(c("Anthropometric", "Lifestyle", "Diet", "Disease",
             "BSS", "PhysicalAcitivity", "Medication"),
             c(5, 2, 16, 12, 5, 1, 20)),
             levels = c("Anthropometric", "Lifestyle", "Diet", "Disease",
                        "BSS", "PhysicalAcitivity", "Medication"))

bar_data <- data.frame(Virome = Virome,
                       Bacteriome = Bacteriome,
                       group = group)

# 排序：
bar_data_sort1 <- bar_data %>%
  group_by(group) %>%
  mutate(Virome = sort(Virome, decreasing = T))

bar_data_sort2 <- bar_data %>%
  group_by(group) %>%
  mutate(Bacteriome = sort(Bacteriome, decreasing = T))

p1 <- ggplot(bar_data_sort1)+
  annotate("rect", xmin = seq(1.5, 59.5, 2),
           xmax = seq(2.5, 60.5, 2), ymin = 0, ymax = 0.2,
           fill = rep("#f5f5f5", 30))+
  geom_hline(yintercept = seq(0.05, 0.2, 0.05), color = "#e6e6e6")+
  geom_col(aes(x = 1:nrow(bar_data_sort1), y = Virome, fill = group))+
  scale_fill_manual(name = "",values = c("#4f6980", "#849db1", "#a2ceaa", "#638b66",
                      "#bfbb60", "#f47942", "#fbb04e"))+
  scale_x_continuous(expand = c(0.005,0.005))+
  scale_y_continuous(expand = c(0.005,0.005))+
  xlab("")+
  theme_bw()+
  theme(axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        legend.position = "top",
        panel.grid = element_blank())+
  guides(fill = guide_legend(nrow = 1))

p1

ggsave("p1.pdf", height = 3, width = 12)

p2 <- ggplot(bar_data_sort2)+
  annotate("rect", xmin = seq(1.5, 59.5, 2),
           xmax = seq(2.5, 60.5, 2), ymin = 0, ymax = 1,
           fill = rep("#f5f5f5", 30))+
  geom_hline(yintercept = seq(0.25, 1, 0.25), color = "#e6e6e6")+
  geom_col(aes(x = 1:nrow(bar_data_sort1), y = Bacteriome, fill = group))+
  scale_fill_manual(values = c("#4f6980", "#849db1", "#a2ceaa", "#638b66",
                               "#bfbb60", "#f47942", "#fbb04e"))+
  scale_x_continuous(expand = c(0.005,0.005))+
  scale_y_continuous(expand = c(0.005,0.005))+
  xlab("")+
  theme_bw()+
  theme(axis.ticks.x = element_blank(),
        axis.text.x = element_blank(),
        legend.position = "none",
        panel.grid = element_blank())+
  scale_y_reverse()

p2

ggsave("p2.pdf", height = 3, width = 12)

p1/p2

ggsave("p1_p2.pdf", height = 6, width = 12)


# 矩阵热图数据：
p_mat <- matrix(NA, nrow = 2, ncol = 61)
colnames(p_mat) <- paste0("featrue_", 1:61)

anno_mat <- matrix(NA, nrow = 2, ncol = 61)
sig_index <- sample(1:122, 20)
p_mat[sig_index] <- runif(20, -20, 20)
anno_mat[sig_index] <- "*"

library(ComplexHeatmap)
library(circlize)

pdf("p3.pdf", height = 1.5, width = 12)
Heatmap(p_mat,
        col = colorRamp2(c(-20, 0, 20),
                         c("#69a9d2", "white", "#c44c4b")),
        na_col = "white",
        cell_fun = function(j, i, x, y, width, height, fill) {
          if(!is.na(anno_mat[i, j])){
            grid.text(sprintf("*"),
                      x, y, gp = gpar(fontsize = 10))}
        },
        rect_gp = gpar(col = "black"),
        cluster_rows = F,
        cluster_columns = F,
        show_heatmap_legend = F)

dev.off()




