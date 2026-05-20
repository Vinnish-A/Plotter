library(circlize)
library(ggplot2)

# 数据构建：
times <- sample(1:3, 15, prob = c(0.2, 0.5, 0.3), replace = T)
data <- data.frame(Inner_value = rep(times, times),
                   Inner_group = rep(1:15, times))
colors <- c("#ecdb91", "#e6d5b5", "#d9a578", "#e7b68a", "#e6b8a1",
            "#c1c4de", "#aaadd1", "#8e91bb", "#8c9dcb",
            "#afaf83", "#afc588", "#b8999b", "#c4abad",
            "#c7c9cb", "#e1d99f")
data$color_Inner <- rep(colors, times)
data$outer <- rep(1, nrow(data))
data$outer_group <- 1:nrow(data)+15

n = 1
j = 2
for (i in 1:nrow(data)) {
  time <- times[data$Inner_group[i]]
  index1 <- data$Inner_group[i]
  data$color_outer[i] <- colorRampPalette(c(colors[n], "white"))(6)[j]
  if (i < nrow(data)) {
    index2 <- data$Inner_group[i+1]
  }
  if (index2 != index1) {
    n = n + 1
    j = 2
  } else {
    j = j + 1
  }
}

library(tidyverse)

data_long <- data.frame(value = c(data$Inner_value, data$outer),
                        x = rep(c("Inner", "Outer"), each = nrow(data)),
                        group = c(data$Inner_group, data$outer_group))
data_long <- unique(data_long)
data_long$group <- factor(data_long$group, levels = 1:nrow(data_long))
data_long$name <- paste0("name", 1:nrow(data_long))
data_long <- data_long %>%
  group_by(x) %>%
  mutate(
    cumsum = cumsum(value),
    cumsum2 = cumsum(value) - value/2,
    angle = (cumsum(value)-value/2)/30*360 + 90)

p1 <- ggplot(data_long)+
  geom_col(aes(x, value, fill = group),
           width = 1,
           position = "stack", color ="white")+
  geom_text(data=data_long[data_long$x == "Outer",],
            aes(x, value, label = name,
                group = group, angle = angle),
            size = 2,
            vjust = -2,
            position = "stack")+
  geom_text(data=data_long[data_long$x == "Inner",],
            aes(x, value, label = name,
                group = group, angle = angle),
            size = 2,
            vjust = -0.5,
            position = "stack")+
  scale_fill_manual(values = c(unique(data$color_Inner), unique(data$color_outer)))+
  theme_void()+
  theme(legend.position = "none")+
  coord_polar(theta = "y")

################### 绘制最外圈环形饼图 ------------
library(scatterpie)

# 设置圆的半径和点的数量
radius <- 1
num_points <- nrow(data)

# 计算每个点的角度
angles <- seq(0, 2 * pi, length.out = num_points)

# 计算每个点的x坐标和y坐标
x_coordinates <- radius * cos(angles)
y_coordinates <- radius * sin(angles)

# 构建数据：
pie_data <- data.frame(x = x_coordinates, y = y_coordinates,
                       group = 1:nrow(data),
                       A = sample(1:10, nrow(data), replace = T),
                       B = sample(1:10, nrow(data), replace = T),
                       C = sample(1:10, nrow(data), replace = T),
                       D = sample(1:10, nrow(data), replace = T))

p2 <- ggplot(pie_data) +
  geom_scatterpie(data = pie_data, aes(x, y, group=group),
                  pie_scale = 1.5,
                  cols = LETTERS[1:4], color = NA) +
  scale_fill_manual(values = c("#ecdb91", "#d9a578","#8e91bb","#b8999b"))+
  coord_equal()+
  theme_void()+
  theme(legend.position = "none")


pdf("plot.pdf", height = 5, width = 5)
vp <- viewport(width = 1,
               height = 1,
               x = 0.5, y = 0.5)
print(p2)
print(p1,vp=vp)
dev.off()
