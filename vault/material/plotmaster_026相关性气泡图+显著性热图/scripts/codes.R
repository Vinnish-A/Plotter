library(ggplot2)
library(tidyverse)
library(Hmisc)

# 构造虚拟数据:
# 首先创建任意矩阵
data <- matrix(runif(20*40, min = -10, max = 10), nrow = 40, ncol = 20)
colnames(data) <- paste0("step", 1:20)

# 计算相关性和显著性p值矩阵：
cor_res <- rcorr(data)

cor_mat <- cor_res$r
p_mat <- cor_res$P

# 数据转换：
cor_mat_long <- cor_mat %>% 
  as.data.frame() %>% 
  mutate(x = factor(rownames(cor_mat), levels = paste0("step", 1:20))) %>% 
  pivot_longer(cols = !x, names_to = "y", values_to = "cor") %>% 
  mutate(y = factor(y, levels = rev(paste0("step", 1:20))))

head(cor_mat_long)
# A tibble: 6 x 3
#   x     y         cor
# <fct> <fct>   <dbl>
#   1 step1 step1  1     
# 2 step1 step2  0.133 
# 3 step1 step3 -0.0930
# 4 step1 step4  0.0691
# 5 step1 step5  0.101 
# 6 step1 step6  0.131 

ggplot() +
  # 气泡图：
  geom_point(data = cor_mat_long, aes(x, y, size = cor, fill = cor), 
             shape = 21, color = "#c4bcba")+
  # 配色：
  scale_fill_gradient2(low = "#4178a7", mid = "#ffffff", high = "#e2201c")+
  # x轴和y轴扩展
  scale_x_discrete(expand = c(0.025, 0.025))+
  scale_y_discrete(expand = c(0.025, 0.025))+
  # 框线
  geom_vline(aes(xintercept =seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  geom_hline(aes(yintercept=seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  # 主题：
  theme_minimal()+
  theme(panel.grid = element_blank())

ggsave("p1.pdf", height = 8, width = 8)

# 取相关性矩阵上三角：
cor_mat_up <- cor_mat
cor_mat_up[lower.tri(cor_mat_up, diag = T)] <- NA

cor_mat_up_long <- cor_mat_up %>% 
  as.data.frame() %>% 
  mutate(x = factor(rownames(cor_mat_up), levels = rev(paste0("step", 1:20)))) %>% 
  pivot_longer(cols = !x, names_to = "y", values_to = "cor") %>% 
  mutate(y = factor(y, levels = paste0("step", 1:20)))

ggplot() +
  # 气泡图：
  geom_point(data = cor_mat_up_long, aes(x, y, size = cor, fill = cor), 
             shape = 21, color = "#c4bcba")+
  # 配色：
  scale_fill_gradient2(low = "#4178a7", mid = "#ffffff", high = "#e2201c")+
  # x轴和y轴扩展
  scale_x_discrete(expand = c(0.025, 0.025))+
  scale_y_discrete(expand = c(0.025, 0.025))+
  # 框线
  geom_vline(aes(xintercept =seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  geom_hline(aes(yintercept=seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  # 主题：
  theme_minimal()+
  theme(panel.grid = element_blank())

ggsave("p2.pdf", height = 8, width = 8)

# 取p值矩阵下三角：
p_mat_lower <- p_mat
p_mat_lower[!lower.tri(p_mat_lower, diag = F)] <- 1

p_mat_lower_long <- p_mat_lower %>% 
  as.data.frame() %>% 
  mutate(x = factor(rownames(p_mat_lower), levels = rev(paste0("step", 1:20)))) %>% 
  pivot_longer(cols = !x, names_to = "y", values_to = "p") %>% 
  mutate(y = factor(y, levels = paste0("step", 1:20)))

# 显著性标记：
p_mat_lower_long$p_sig <- as.character(symnum(p_mat_lower_long$p, 
                                              cutpoints = c(0, 0.001, 0.01, 0.05, 1), 
                                              symbols = c("***", "**", "*", "")))
ggplot() +
  # 气泡图：
  geom_point(data = p_mat_lower_long, 
             aes(x, y, color = -log10(p)),
             size = 10,
             shape = 15)+
  geom_text(data = p_mat_lower_long, 
            aes(x, y, label = p_sig))+
  # 配色：
  scale_color_gradientn(colours = c("#ffffff", "#71bc68", "#c3972e", "#fb7f00"))+
  # x轴和y轴扩展
  scale_x_discrete(expand = c(0.025, 0.025))+
  scale_y_discrete(expand = c(0.025, 0.025))+
  # 框线
  geom_vline(aes(xintercept =seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  geom_hline(aes(yintercept=seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  # 主题：
  theme_minimal()+
  theme(panel.grid = element_blank())

ggsave("p3.pdf", height = 8, width = 8.5)

ggplot() +
  # p值矩阵：
  geom_point(data = p_mat_lower_long, 
             aes(x, y, color = -log10(p)),
             size = 10,
             shape = 15)+
  geom_text(data = p_mat_lower_long, 
            aes(x, y, label = p_sig))+
  # 配色：
  scale_color_gradientn(colours = c("#ffffff", "#71bc68", "#c3972e", "#fb7f00"))+
  # 气泡图：
  geom_point(data = cor_mat_up_long, aes(x, y, size = cor, fill = cor), 
             shape = 21, color = "#c4bcba")+
  # 配色：
  scale_fill_gradient2(low = "#4178a7", mid = "#ffffff", high = "#e2201c")+
  # x轴和y轴扩展
  scale_x_discrete(expand = c(0.025, 0.025))+
  scale_y_discrete(expand = c(0.025, 0.025), position = "right")+
  # 框线
  geom_vline(aes(xintercept =seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  geom_hline(aes(yintercept=seq(0.5, 20.5, 1)), color = "#bbbbbb")+
  # 主题：
  xlab("")+
  ylab("")+
  theme_minimal()+
  theme(panel.grid = element_blank(), 
        axis.text.x = element_text(angle = 90),
        legend.position = "top")+
  guides(fill = guide_colorbar("correlation", title.position = "top",
                               title.theme = element_text(face = "bold")),
         color = guide_colorbar("-log10(P value)", title.position = "top",
                                title.theme = element_text(face = "bold")),
         size = "none")

ggsave("plot.pdf", height = 8.3, width = 7.3)
