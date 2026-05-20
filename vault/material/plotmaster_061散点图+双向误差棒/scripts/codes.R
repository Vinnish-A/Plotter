library(tidyverse)
library(ggplot2)

############ 模拟数据构建 ----------------
# x值：
set.seed(123)
xmin <- runif(40)
xmax <- xmin + runif(40, 0.01, 0.08)

# y值：
set.seed(234)
ymin <- runif(40)
ymax <- ymin + runif(40, 0.01, 0.08)

# 数据框：
data <- data.frame(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax)
data <- data %>%
  mutate(xmean = (xmin+xmax)/2, ymean = (ymin+ymax)/2)

# 分组信息：
data$group1 <- rep(c(LETTERS[1:5], LETTERS[1:5]), 4)
data$group2 <- rep(c("E10", "E12", "E15", "E18"), each = 10)
data$group3 <- rep(c(rep("WT", 5), rep("AK", 5)), 4)

################# 绘图 --------------
ggplot(data, aes(x = xmean, y = ymean)) +
  # 横向误差棒：
  geom_errorbarh(aes(xmin = xmin, xmax = xmax,
                     color = group1, alpha = group2),
                 height = 0.01, linewidth = 0.2) +
  # 纵向误差棒：
  geom_errorbar(aes(ymin = ymin, ymax = ymax,
                    color = group1, alpha = group2),
                width = 0.01, linewidth = 0.2) +
  # 散点:
  geom_point(aes(fill = group1, alpha = group2, shape = group3))+
  # 斜线：
  geom_abline(intercept = 0, slope = 1, linetype = "dashed")+
  # 颜色模式：
  scale_fill_manual(values = c("#ffffff", "#ffae47", "#1e78c2", "#d44966", "#4b9258"))+
  scale_color_manual(values = c("#ffffff", "#ffae47", "#1e78c2", "#d44966", "#4b9258"))+
  scale_shape_manual(values = c(21, 22))+
  scale_alpha_manual(values = c(0.4, 0.6, 0.8, 1))+
  labs(x = "Fraction labeled aKG",
       y = "Fraction labeled glutamate") +
  theme_classic()+
  theme(legend.position = "none")

ggsave("plot.pdf", height = 4, width = 4.2)









