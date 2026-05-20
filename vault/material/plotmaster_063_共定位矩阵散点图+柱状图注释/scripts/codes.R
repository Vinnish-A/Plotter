library(tidyverse)
library(readxl)

################# 1.读取数据+预处理 ----------------
data <- read_excel("data.xlsx") %>% column_to_rownames("#")

# 采用Nearby genesb的第一个基因作为label：
data$`Nearby genesb` <- str_split(data$`Nearby genesb`, ", ", simplify = T)[,1]

# 将数据转换为lipid-loci和coronary artery disease的矩阵：
# 有共定位关系的标记为1；
# 使用tidyr的separate_rows将Genes列拆分为多行
df_long <- data[,c(1, 4, 8)] %>%
  tidyr::separate_rows("Co-localised lipid classes", sep = ", ")  %>%
  mutate("values" = 1) # vlaues用来关联散点的大小；
colnames(df_long) <- c("rsID", "class", "gene", "values")

# 添加分组信息和CAD行：
df_CAD <- data.frame("rsID" = unique(df_long$rsID),
                     "class" = "CAD",
                     "gene" = data$`Nearby genesb`,
                     "values" = 0.5)
df_long <- rbind(df_long, df_CAD)

group_data <- read.csv("group.csv")
df_long <- full_join(df_long, group_data, by = "class")
df_long$class <- factor(df_long$class, levels = rev(group_data$class))

# 添加最大值点，用于绘制灰色线条：
df_long$class_ID <- as.numeric(df_long$class)
df_long <- df_long %>%
  group_by(class) %>%
  mutate(max_ID = max(class_ID)) %>%
  ungroup()

# 最底层小灰点数据：
df_wide <- df_long %>%
  pivot_wider(names_from = rsID, values_from = values, values_fill = 0.5)
df_point <- df_wide[,-c(2:5)] %>%
  pivot_longer(cols = -class,
               names_to = "rsID",
               values_to = "values")


################# 2. 绘图 -----------------
##### 共表达散点图：
p1 <- ggplot(df_long)+
  # 阴影绘制：
  annotate(geom = "rect",
           xmin = 0, xmax = nrow(data),
           ymin = seq(0.5, length(group_data$class)-0.5, 2),
           ymax = seq(1.5, length(group_data$class)+0.5, 2),
           fill = "grey80", alpha = 0.5) + # 绘制阴影
  # 灰色散点：
  geom_point(data = df_point, aes(rsID, class), color = "#d2d2d2", size = 0.3)+
  # 竖线：
  geom_linerange(aes(x = rsID, ymin = 1, ymax = max_ID),
                 color = "grey", linewidth = 0.8)+
  # 散点：
  geom_point(aes(rsID, class, size = values, color = group))+
  # 默认的panel显示不出来，去AI中设置一下就行(释放剪切蒙版就出来了)：
  geom_text(aes(x = rsID, y = length(unique(class))+1, label = gene),
            angle = 70, size = 1.5, hjust = 0)+
  scale_size_continuous(range = c(1, 1.5))+
  ggsci::scale_color_futurama()+
  xlab("")+
  ylab("")+
  ggtitle("")+
  theme_minimal()+
  theme(panel.grid = element_blank(),
        panel.margin = unit(c(1,1,1,1), "cm"),
        axis.text.y = element_text(hjust = 0.5),
        axis.text.x = element_text(angle = 70, hjust = 1),
        legend.position = "none")


#### 柱状图：
bar_data <- df_long %>%
  group_by(class) %>%
  summarise(bar_value = n(), group = first(group), .groups = "drop")

bar_data$bar_value <- -bar_data$bar_value

p2 <- ggplot(bar_data)+
  geom_col(aes(class, bar_value, fill = group), color = "black")+
  ggsci::scale_fill_futurama() +  # 自定义填充颜色
  coord_flip()+
  scale_y_continuous(labels = rev(seq(0, 40, 10)), expand = c(0, 0))+
  xlab("")+
  ylab("Number of unique colocalized loci")+
  theme_classic()+
  theme(axis.line.y = element_blank(),
        axis.text.y = element_blank(),
        axis.ticks.y = element_blank(),
        legend.position = "none")

#### 拼图：
pdf("plot.pdf", height = 6, width = 13)
p2+p1 + plot_layout(widths = c(1, 3))
dev.off()

