library(ggplot2)
library(tidyverse)

# 读取初步数据：
data <- read.csv("data.csv", header = F)

# 绘制散点数据：构造过程略微复杂，需要仔细琢磨才能看懂
plot_data <- data.frame(x = c(rep(c(0,1), each = 14), rep(c(1,2), each = 15)),
                        y = c(11-as.numeric(str_split(data$V1[1:14], "_", simplify = T)[,2]),
                              11-as.numeric(gsub("c","", data$V2[1:14])),
                              11-as.numeric(gsub("c","", data$V2[15:nrow(data)])),
                              11-as.numeric(str_split(data$V1[15:nrow(data)], "_", simplify = T)[,2])*(11/12)),
                        group = c(rep(c(1:14), 2), rep(15:nrow(data), 2)),
                        color = c(data$V1[1:14], rep("cluster", 14),
                                  rep("cluster", 15), data$V1[15:nrow(data)]),
                        text = c(data$V1[1:14],data$V2[1:14],
                                 data$V2[15:nrow(data)], data$V1[15:nrow(data)]),
                        values = c(rep(data$V3[1:14], 2),
                                   rep(data$V3[15:nrow(data)], 2)))

# 绘制曲线的数据：
line_data <- data.frame(x = rep(c(0,1), c(14,15)),
                        xend = rep(c(1,2), c(14,15)),
                        y = plot_data$y[c(1:14, 29:43)],
                        yend = plot_data$y[c(15:28, 44:58)],
                        values = plot_data$values[c(1:14, 29:43)],
                        group = factor(1:29),
                        color = plot_data$color[c(1:14, 44:58)])

# 绘制文本所需的数据：
text_data <- data.frame(x = rep(c(-0.1, 1, 2.1), c(11, 11, 12)),
                        y = c(11:1, 11:1, 12:1),
                        label = c(unique(data$V1)[1:11], paste0("c", 1:11),
                                  unique(data$V1)[12:23]))

# 配色：
library(RColorBrewer)
color_value <- c("#a62a2a", "#43a85e", "#8dd3c8", "#b3de6a", "#bc80bc",
                 "#bebbd7", "#c6dbf0", "#80b0d1", "#fc7e74", "#fc9db6", "#fbb366",
                 "#fbc1cb",
                 brewer.pal(12, "Paired"))
names(color_value) <- unique(plot_data$color)


########## 绘图 ----------------
ggplot(plot_data)+
  # 曲线：
  geom_sigmoid(data = line_data,
               aes(x = x, xend = xend,
                   y = y, yend = yend, size = values,
                   group = group, color = color))+
  # 散点：
  geom_point(aes(x, y, color = color), size = 4)+
  # 由于对齐方式不一样，所以分三组绘制文本：
  geom_text(data = text_data %>% filter(grepl("^h", label)),
            aes(x, y-1, label = label), hjust = 1)+
  geom_text(data = text_data %>% filter(grepl("^c", label)),
            aes(x, y-1, label = label), hjust = 0.5)+
  geom_text(data = text_data %>% filter(grepl("^m", label)),
            aes(x, (y-1)*11/12, label = label), hjust = 0)+
  # 曲线宽度范围：
  scale_size_continuous(range = c(0.2, 1))+
  # 颜色：
  scale_color_manual(values = color_value)+
  xlim(-0.4, 2.5)+
  # 主题：
  theme_void() +
  theme(legend.position = "none")

# 保存：
ggsave("plot.pdf", height = 5, width = 9)

