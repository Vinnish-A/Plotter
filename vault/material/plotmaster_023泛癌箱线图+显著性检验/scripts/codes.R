# 载入R包：
library(ggplot2)
library(ggpubr)
library(tidyverse)
library(latex2exp)
library(rstatix)

# 读取数据：
data <- read.csv("hsa-let-7a-5p.TCGA_PanCancer_Expression_Data.csv", header = T)
head(data)
#             mir   project          sample group   expr
# 1 hsa-let-7a-5p TCGA-BRCA TCGA-3C-AAAU-01 Tumor 15.171
# 2 hsa-let-7a-5p TCGA-BRCA TCGA-3C-AALI-01 Tumor 15.494
# 3 hsa-let-7a-5p TCGA-BRCA TCGA-3C-AALJ-01 Tumor 15.453
# 4 hsa-let-7a-5p TCGA-BRCA TCGA-3C-AALK-01 Tumor 15.592
# 5 hsa-let-7a-5p TCGA-BRCA TCGA-4H-AAAK-01 Tumor 15.967
# 6 hsa-let-7a-5p TCGA-BRCA TCGA-5L-AAT0-01 Tumor 16.044

# 绘图：
ggplot(data)+
  # 基础图形：
  geom_boxplot(aes(project, expr, fill = group))+
  # 设置颜色：
  scale_fill_manual(values = c("Tumor" = "#d6503a", "Normal" = "#5488ef"))+
  # 设置主题：
  theme_bw()+
  theme(axis.text = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1))

# 按中位数由高到低排列：
data_new <- data %>% 
  group_by(project) %>% 
  mutate(median = median(expr), group_max = max(expr)) %>% 
  arrange(desc(median))

# 调整因子顺序：
data_new$project <- factor(data_new$project, levels = unique(data_new$project))

data_new1 <- data_new %>% 
  group_by(project) %>% 
  mutate(group_number = length(unique(group)))

# 此数据用于添加显著性检验的label：
stat.test <- data_new1[which(data_new1$group_number == 2),] %>%
  group_by(project) %>%
  pairwise_t_test(
    expr ~ group, paired = FALSE, 
    p.adjust.method = "fdr"
  ) %>% 
  add_xy_position(x = "project")

stat.test

# 重新画图：
ggplot()+
  # 基础图形：
  geom_boxplot(data = data_new, aes(x = project, y =expr, fill = group),outlier.shape = 21, outlier.fill = "white")+
  # 设置颜色：
  scale_fill_manual(name = NULL, values = c("Tumor" = "#d6503a", "Normal" = "#5488ef"))+
  # 设置主题：
  theme_bw()+
  labs(y = TeX("miRNA Level ($log_{2}$CPM)", bold = T))+
  theme(axis.text = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        axis.line = element_line(colour = "black"),
        panel.border = element_blank(),
        panel.background = element_blank(),
        legend.position = c(0.99, 0.99), 
        legend.justification = c(1,1))+
  # 显著性检验：
  stat_pvalue_manual(
    stat.test, label = "p.adj.signif", 
    bracket.size = 0.3, # 粗细
    tip.length = 0.01  # 两边竖线的长度
  )

ggsave("box_plot.pdf", height = 6, width = 10)

