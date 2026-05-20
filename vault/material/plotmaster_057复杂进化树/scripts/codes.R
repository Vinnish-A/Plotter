# 加载R包：
library(ggplot2)
library(ggtree)
library(tidyverse)

##################### 数据构建 ------------------
set.seed(123)
# 由于文献没有提供进化树文件
# 这里就采用iris数据集的聚类树代替进化树进行后续绘图；
data(iris)

# 随机挑100个样本：
data <- iris[sample(1:nrow(iris), 100),1:4]
rownames(data) <- paste0("Sample", 1:nrow(data))

# 聚类树：
tree <- hclust(dist(data))
plot(tree)

##################### 绘图 ------------------
{
pdf("plot.pdf", height = 5, width = 5)

p <- ggtree(tree, layout = "circular", linewidth = 0.2)+
  xlim(0, 5)+
  # 这里根据节点编号设置背景色:
  geom_cladelab(node = c(110, 106), label = "",
                barcolor = "#b6e2fb",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = c(117, 130), label = "",
                barcolor = "#b3fe7d",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = 131, label = "",
                barcolor = "#ecc6eb",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = 104, label = "",
                barcolor = "#d0edf1",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = 127, label = "",
                barcolor = "#fed9e0",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = c(108, 114, 144), label = "",
                barcolor = "#92ede4",
                barsize = 35, extend=0.7, offset = 1.3)+
  geom_cladelab(node = c(145, 128), label = "",
                barcolor = "#fac9a1",
                barsize = 35, extend=0.7, offset = 1.3)+
  # 随机再选几个节点变成灰色：
  geom_cladelab(node = c(162, 192, 170, 155, 168, 27, 67), label = "",
                barcolor = "#666666",
                barsize = 35, extend=0.5, offset = 1.3)+
  # 查看节点编号，使用后可以注释掉：
  # geom_text(aes(label = node), size = 1, color = "red")+
  geom_tiplab2(offset = 0.3, size = 1.5, fontface = "italic")

p
# 通过上面的节点编号可以看出，中间节点的编号为101-199：
# 随机创建：中间节点的分组文件：
group_Y <- sample(101:197, 40)
group_G <- sample(setdiff(101:199, a), 30)
group_R <- sample(setdiff(setdiff(101:199, a), b), 27)


p_new <- p +
  # 中间节点：
  geom_point2(aes(subset=(node %in% group_Y)),
              shape=16, size=1, color ='#fed500')+
  geom_point2(aes(subset=(node %in% group_G)),
              shape=16, size=1, color ='#017c07')+
  geom_point2(aes(subset=(node %in% group_R)),
              shape=16, size=1, color ='#ff0007')+
  # 末端节点：
  geom_point2(aes(subset=(node %in% c(23, 80, 9, 70)), x = x+0.1),stroke = 0.2,
              shape=21, size = 1.5, fill ='#b6e2fb')+
  geom_point2(aes(subset=(node %in% c(64, 95)), x = x+0.1), stroke = 0.2,
              shape=21, size = 1.5, fill ='#b3fe7d')+
  geom_point2(aes(subset=(node %in% c(21, 71)), x = x+0.1), stroke = 0.2,
              shape=21, size = 1.5, fill ='#ecc6eb')+
  geom_point2(aes(subset=(node %in% c(83, 92)), x = x+0.1), stroke = 0.2,
              shape=21, size = 1.5, fill ='#d0edf1')+
  geom_point2(aes(subset=(node %in% c(27, 67)), x = x+0.1), stroke = 0.2,
              shape=21, size = 1.5, fill ='#fac9a1')

print(p_new)
dev.off()
}

# 最外圈的注释没想到什么好的方式添加，可以用AI手动加一下！

