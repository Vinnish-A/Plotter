# 构造虚拟数据集：
data <- cbind(runif(21, 0, 10), runif(21, 0, 10), rep(5,21))
data <- as.data.frame(data)
data[1,] <- c(5,5,5)

# 载入需要用到的R包：
library(ggplot2)
library(tidyr)
library(ggtext)
library(patchwork)
library(png)
library(grid)

# 数据重构：
data <- gather(data, "X", "Y")
data$gene <- factor(rep(c("",paste("gene",1:20)),3),levels = rev(c("",paste("gene",1:20))))


############# 绘图 ##################
p1 <- ggplot(data, aes(X,gene))+
  geom_tile(aes(fill=Y),color="white",size=5)+ #color和size分别指定方块边线的颜色和粗细
  scale_x_discrete("",expand = c(0,0))+ #不显示横纵轴的label文本；画板不延长
  scale_y_discrete("",expand = c(0,0))+
  scale_fill_gradientn(values =seq(0,1,0.2),
                       colors =c("#bc2a35", "#dc6e57", "#ffffff", "#85bcda", "#4c99c7"))+ #指定自定义的颜色
  # 设置主题：
  theme(
    plot.title.position = "plot",
    plot.title = element_text(hjust = 0.7),
    # 去掉X轴的刻度标签:
    axis.text.x = element_blank(),
    axis.text.y.left = element_text(size = 12), #修改坐标轴文本大小
    axis.ticks = element_blank(), #不显示坐标轴刻度
    legend.title = element_blank(), #不显示图例title
    legend.position = "none"
  )+
  # 设置标题：
  labs(title = "PFC          \n————————      \nCtrl      CUMS      ")

# 读取图片：
mouseL <- readPNG("mouseL.png")
L <- rasterGrob(mouseL, interpolate=TRUE)
mouseR <- readPNG("mouseR.png")
R <- rasterGrob(mouseR, interpolate=TRUE)

# 将小鼠图片添加到图形中：
p1 <- p1 + annotation_custom(L, xmin=0.5, xmax=1.5, ymin=20.5, ymax=21.5) +
  annotation_custom(R, xmin=1.5, xmax=2.5, ymin=20.5, ymax=21.5)


# 使用for循环添加箭头：
arrowUp <- readPNG("up.png")
Up <- rasterGrob(arrowUp, interpolate=TRUE)
arrowDown <- readPNG("down.png")
Down <- rasterGrob(arrowDown, interpolate=TRUE)

# 随机创建一组上下调情况：
Regulation_data <- sample(c(0,1),20,replace = TRUE)

# for循环将箭头摆放到合适位置：
for (i in 1:20) {
  if (Regulation_data[i] == 1) {
    p1 = p1 + annotation_custom(Up, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  } else {
    p1 = p1 + annotation_custom(Down, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  }
}




############# p2 ##################
# 为了节约篇幅，我就直接用同一个数据了！
p2 <- ggplot(data, aes(X,gene))+
  geom_tile(aes(fill=Y),color="white",size=5)+ #color和size分别指定方块边线的颜色和粗细
  scale_x_discrete("",expand = c(0,0))+ #不显示横纵轴的label文本；画板不延长
  scale_y_discrete("",expand = c(0,0))+
  scale_fill_gradientn(values =seq(0,1,0.2),
                       colors =c("#bc2a35", "#dc6e57", "#ffffff", "#85bcda", "#4c99c7"))+ #指定自定义的颜色
  # 设置主题：
  theme(
    plot.title.position = "plot",
    plot.title = element_text(hjust = 0.7),
    # 去掉X和y轴的刻度标签:
    axis.text.x = element_blank(),
    axis.text.y = element_blank(), 
    axis.ticks = element_blank(), #不显示坐标轴刻度
    legend.title = element_blank(), #不显示图例title
    legend.position = "none"
  )+
  # 设置标题：
  labs(title = "PFC                 \n————————           \nCtrl      CUMS           ")

# 读取图片：
mouseL <- readPNG("mouseL.png")
L <- rasterGrob(mouseL, interpolate=TRUE)
mouseR <- readPNG("mouseR.png")
R <- rasterGrob(mouseR, interpolate=TRUE)

# 将小鼠图片添加到图形中：
p2 <- p2 + annotation_custom(L, xmin=0.5, xmax=1.5, ymin=20.5, ymax=21.5) +
  annotation_custom(R, xmin=1.5, xmax=2.5, ymin=20.5, ymax=21.5)


# 使用for循环添加箭头：
arrowUp <- readPNG("up.png")
Up <- rasterGrob(arrowUp, interpolate=TRUE)
arrowDown <- readPNG("down.png")
Down <- rasterGrob(arrowDown, interpolate=TRUE)

# 随机创建一组上下调情况：
Regulation_data <- sample(c(0,1),20,replace = TRUE)

# for循环将箭头摆放到合适位置：
for (i in 1:20) {
  if (Regulation_data[i] == 1) {
    p2 = p2 + annotation_custom(Up, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  } else {
    p2 = p2 + annotation_custom(Down, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  }
}




############# p3 ##################
# 为了节约篇幅，我就直接用同一个数据了！
p3 <- ggplot(data, aes(X,gene))+
  geom_tile(aes(fill=Y),color="white",size=5)+ #color和size分别指定方块边线的颜色和粗细
  scale_x_discrete("",expand = c(0,0))+ #不显示横纵轴的label文本；画板不延长
  scale_y_discrete("",expand = c(0,0))+
  scale_fill_gradientn(values =seq(0,1,0.2),
                       colors =c("#bc2a35", "#dc6e57", "#ffffff", "#85bcda", "#4c99c7"))+ #指定自定义的颜色
  # 设置主题：
  theme(
    plot.title.position = "plot",
    plot.title = element_text(hjust = 0.7),
    # 去掉X和y轴的刻度标签:
    axis.text.x = element_blank(),
    axis.text.y = element_blank(), 
    axis.ticks = element_blank(), #不显示坐标轴刻度
    legend.title = element_blank(), #不显示图例title
    legend.position = "none"
  )+
  # 设置标题：
  labs(title = "PFC                 \n————————           \nCtrl      CUMS           ")

# 读取图片：
mouseL <- readPNG("mouseL.png")
L <- rasterGrob(mouseL, interpolate=TRUE)
mouseR <- readPNG("mouseR.png")
R <- rasterGrob(mouseR, interpolate=TRUE)

# 将小鼠图片添加到图形中：
p3 <- p3 + annotation_custom(L, xmin=0.5, xmax=1.5, ymin=20.5, ymax=21.5) +
  annotation_custom(R, xmin=1.5, xmax=2.5, ymin=20.5, ymax=21.5)


# 使用for循环添加箭头：
arrowUp <- readPNG("up.png")
Up <- rasterGrob(arrowUp, interpolate=TRUE)
arrowDown <- readPNG("down.png")
Down <- rasterGrob(arrowDown, interpolate=TRUE)

# 随机创建一组上下调情况：
Regulation_data <- sample(c(0,1),20,replace = TRUE)

# for循环将箭头摆放到合适位置：
for (i in 1:20) {
  if (Regulation_data[i] == 1) {
    p3 = p3 + annotation_custom(Up, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  } else {
    p3 = p3 + annotation_custom(Down, xmin=2.5, xmax=3.5, ymin=20-i+0.8, ymax=20-i+1.2)
  }
}

p1|p2|p3

ggsave("heatmap.pdf", height = 10, width = 8.5)


