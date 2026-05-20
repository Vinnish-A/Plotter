library(ggradar)
library(tidyverse)

# 构造模拟数据：
data <- data.frame(
  row.names = LETTERS[1:5],
  `T cell activation` = c(1, 0.3, 0.2, 0.1, 0.1),
  `Neutrophil immunity` = c(0.3, 1, 0.2, 0.1, 0.1),
  `ECM organization` = c(0.3, 0.2, 1, 0.1, 0.1),
  `Hepatic metabolism` = c(0.3, 0.2, 0.1, 1,  0.1),
  `Cell migration` = c(0.3, 0.2, 0.1, 0.1, 1)
)

# 将行名改为分组列
df <- as.data.frame(t(data)) %>% rownames_to_column("group")
df
#                 group   A   B   C   D   E
# 1   T.cell.activation 1.0 0.3 0.2 0.1 0.1
# 2 Neutrophil.immunity 0.3 1.0 0.2 0.1 0.1
# 3    ECM.organization 0.3 0.2 1.0 0.1 0.1
# 4  Hepatic.metabolism 0.3 0.2 0.1 1.0 0.1
# 5      Cell.migration 0.3 0.2 0.1 0.1 1.0

############## 雷达图 ------------
p2 <- ggradar(
  df,
  axis.labels = rep(NA, 5),
  grid.min = 0, grid.mid = 0.5, grid.max = 1,
  # 雷达图线的粗细和颜色：
  group.line.width = 1,
  group.point.size = 2,
  group.colours = c("#f39b7f", "#00a087", "#3c5488", "#4dbbd5", "#e64b35"),
  # 背景边框线颜色：
  background.circle.colour = "white",
  gridline.mid.colour = "#2b8c96",
  legend.position = "none",
  # 不加坐标轴标签：
  label.gridline.min = F,
  label.gridline.mid = F,
  label.gridline.max = F
)+
  theme(plot.background = element_blank(),
        panel.background = element_blank())
p2



############## 圆环注释+文本注释 ------------
library(ggplot2)

# 注释数据：
tmp <- data.frame(x = rep(1, 5),
                  y = rep(1, 5),
                  group = colnames(df)[-1])

# 绘图：
p1 <- ggplot()+
  # 圆环：
  geom_bar(data = tmp, aes(x, y, fill = group), stat = "identity", position = "dodge")+
  # 文本注释：
  geom_text(aes(x = rep(1,25), y = rep(2, 25),
                label = paste0("GENE", LETTERS[1:25]), group = 1:25),
            color = "black", size = 2.5,
            position = position_dodge(width = 0.9))+
  # geom_text(aes(x, y, label = gsub("[.]", " ", df$group), group = group),
  #           color = "white",
  #           position = position_dodge(width = 0.9))+
  scale_fill_manual(values = c("#e64b35", "#4dbbd5", "#00a087", "#3c5488", "#f39b7f"))+
  ylim(-5.5,2)+
  # 0.63是计算得来，5个色块，第一个色块的正中心要对准0的位置，
  # 所以2pi/10=0.628即为第一个色块左边界的位置
  coord_polar(start = -0.63)+
  theme_void()+
  theme(legend.position = "none")

p1

######## 拼图 ---------------------
library(patchwork)

p1 + inset_element(p2, left = 0, bottom = 0, right = 0.99, top = 0.99)

ggsave("plot.pdf", height = 5, width = 5)
