library(tidyverse)
#install.packages("legendry")
library(legendry)
library(RColorBrewer)

sessionInfo()

# 聚类
car_clust <- hclust(dist(scale(mtcars)), "ave")
var_clust <- hclust(dist(scale(t(mtcars))), "ave")
# 构建数据
long_mtcars <- data.frame(
  car = rownames(mtcars)[row(mtcars)],
  var = colnames(mtcars)[col(mtcars)],
  value = as.vector(scale(mtcars)))

p <- ggplot(long_mtcars, aes(var, car, fill = value)) +
  geom_tile(color="grey") +
  scale_fill_gradientn(
    colours = rev(colorRampPalette(brewer.pal(11, "RdBu")[3:9])(200)),
    na.value = "white") +
  scale_x_dendro(var_clust) +
  scale_y_dendro(car_clust)
# 极坐标化
p + coord_radial(theta = "y",
               inner.radius = 0.5,
               start = 0.25 * pi, end = 1.95 * pi,
               clip="off") +
  guides(theta = primitive_labels(angle = 90),
    theta.sec = primitive_segments("dendro",vanish = TRUE),
    r = guide_axis_dendro(angle = 0)) +
  theme(panel.background = element_blank(),
        axis.title = element_blank(),
        legend.background = element_blank(),
        legend.position = c(1.1,0.5),
        plot.margin = margin(0.5,0.5,1,0,unit="cm"))

