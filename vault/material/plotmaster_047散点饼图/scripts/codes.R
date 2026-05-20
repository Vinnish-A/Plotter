library(scatterpie)
library(tidyverse)
library(readxl)

# 这张图作者提供了示例数据，直接读取：
data <- read_excel("sciimmunol.abn6429_data_s1_to_s7/Data file S7.xlsx", sheet = 7)
colnames(data)[5:12] <- data[1, 5:12]
colnames(data)[4] <- "Proportion"
data <- as.data.frame(data[-1, ]) %>% filter(Tissue == "BM")

# 数据类型转换：
for (i in 4:12) {
  data[,i] <- as.numeric(unlist(data[,i]))
}

# 转换x轴信息为因子，最终转为数值：
data$Time <- factor(data$Time, levels = c("d1", "d14", "d21", "d30", "d60", "d90", ">d180"))
data <- data[order(data$Time), ]
data$x <- 1:nrow(data)-0.5
data$region <- factor(1:nrow(data))

# 去掉前两列：
data_new <- data[,-c(1:2)]

head(data_new)
# Time Proportion   ProNeu   PreNeu MatureNeu   Monocyte          B          T NK
# 6    d1  1.8108652 0.000000 1.587302  39.68254   3.174603 25.3968254 30.1587302  0
# 11   d1 18.7098657 0.000000 0.000000  96.72387   2.496100  0.4680187  0.3120125  0
# 16   d1  0.1209190 0.000000 0.000000   0.00000   0.000000  0.0000000 50.0000000 50
# 21   d1  1.7464678 1.123596 0.000000  12.35955  21.348315 52.8089888  6.7415730  0
# 7   d14  1.0000000 0.000000 0.000000   0.00000 100.000000  0.0000000  0.0000000  0
# 12  d14  0.1291572 0.000000 0.000000  25.00000   0.000000 25.0000000 50.0000000  0
# Megakaryocyte   x region
# 6       0.000000 0.5      1
# 11      0.000000 1.5      2
# 16      0.000000 2.5      3
# 21      5.617978 3.5      4
# 7       0.000000 4.5      5
# 12      0.000000 5.5      6

# 设置颜色：
col_values <- c("#325939", "#6eaa62", "#b4d79f", "#f2d533",
                "#8daed1", "#6752a1", "#9d9ac5", "#e36944")
# 绘图：
ggplot()+
  # 散点饼图：
  geom_scatterpie(aes(x = x, y = Proportion, group = region),
                  color = NA, pie_scale = 1,
                  cols = colnames(data_new)[3:10],
                  data = data_new) +
  # 虚线：
  geom_vline(xintercept = cumsum(as.numeric(table(data_new$Time)))[-7],
             linetype = "dashed", color = "grey")+
  # x轴刻度调节：
  scale_x_continuous(breaks = c(2, 6, 10.5, 15, 19.5, 23),
                     labels = c("d1\n(n = 4)", "d14\n(n = 4)", "d30\n(n = 5)",
                                "d60\n(n = 4)", "d90\n(n = 5)", ">d180\n(n = 2)"),
                     expand = c(0,0))+
  # 主题和标签：
  ylab("Proportion of residual cells in TNCs(%)")+
  scale_fill_manual(name = "Cell type", values = col_values)+
  coord_equal()+
  theme_classic()

# 保存
ggsave("plot.pdf", height = 5, width = 7)












