library(tidyverse)
library(RColorBrewer)
library(MetBrewer)
library(patchwork)

sessionInfo()

df <- read_tsv("data1.tsv")

df$n1 <- factor(df$n1,levels = rev(unique(df$n1)))
df$n2 <- factor(df$n2,levels = rev(unique(df$n2)))

# 配对连线图
# 按层级将数据拆分进行格式转换
p1 <- ggplot(df) +
  geom_segment(aes(x = 1, xend = 2,
                   y = n1, yend = n2,
                   color = Host),linewidth=0.8, alpha = 0.8) +
  # 绘制左侧点
  geom_point(aes(x = 1, y = n1),
             size=3,pch=21,color="black",fill="white")+
  # 绘制右侧点
  geom_point(aes(x = 2, y = n2),
             size=3,pch=21,color="black",fill="white")+
  # 添加文本
  geom_text(aes(x = 1, y = n1, label = cluster),
            hjust =1.2, size = 3,vjust=0.5)+
  geom_text(aes(x = 2, y = n2, label = Host),
            size = 3,vjust=0.5,hjust=-0.1) +
  scale_x_continuous(breaks = c(1,2), 
                     labels = c("Cluster", "Host"),
                     limits = c(0.5, 2.5),position = "top") +
  scale_color_brewer(palette = "Paired") +
  coord_cartesian(clip="off") +
  theme(axis.title = element_blank(),
        axis.text.y = element_blank(),
        axis.text.x = element_text(color="black",face="bold"),
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        legend.position = "none",
        plot.margin = margin(0,1,0,0,unit="cm"))
# 获取左右的位点信息
l <- ggplot_build(p1)$data[[4]] %>% select(2,3) %>% distinct()
r <- ggplot_build(p1)$data[[5]] %>% select(2,3) %>% distinct()

# 上方步骤就是该配对图的关键点，现在得到了每一个标签的位点信息，只需要将热图的Y轴文本转换使用数值位点即可。

# 绘制左侧热图
df2 <- read_tsv("data.tsv") %>% pivot_longer(-cluster)
# 定义颜色
col <- colorRampPalette(brewer.pal(11, "RdBu")[3:9])(100)

# 将原始数据与获取的位点信息连接
p2 <- df2 %>% left_join(.,l,by=c("cluster"="label")) %>% 
  ggplot(aes(name,y,fill=value)) +
  geom_tile(color="black",linewidth = 0.5)+
  scale_x_discrete(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_gradientn(colors=col) +
  theme_test() +
  theme(axis.ticks = element_blank(),
        axis.title = element_blank(),
        axis.text.y=element_blank(),
        axis.text.x=element_text(
          angle = 45,color="black",vjust=1,hjust=1),
        plot.margin = margin(0,0.3,0,0.3,unit="cm"),
        legend.title = element_blank(),
        legend.key.height = unit(1,"null"),
        legend.position = "left")


# 右侧热图 此处有一点细节需要注意，看代码中注释
df3 <- read_csv("data2.csv") %>% column_to_rownames(var="label") %>% 
  scale() %>% 
  as.data.frame() %>% rownames_to_column(var="label")

df3 <- read_csv("data2.csv") %>% column_to_rownames(var="label") %>% 
  scale() %>%  # 标准化
  as.data.frame() %>% rownames_to_column(var="label")

p3 <- df3 %>% left_join(.,r,by="label") %>%
  pivot_longer(-c("label","y")) %>% 
  # 此处对y轴数值-0.5让其文本对齐
  ggplot(aes(name,y=y-0.5))+
  geom_tile(color="black",fill="white",linewidth = 0.2)+
  geom_point(aes(fill=value,size=value),pch=21) +
  scale_x_discrete(expand = c(0,0)) +
  # 由于左侧热图有22行，因此此处设置limits为0至22
  scale_y_continuous(expand= c(0,0),limits = c(0,22)) +
  scale_fill_gradientn(colors=met.brewer("Hiroshige"),
                       na.value = "white") +
  guides(size="none") +
  coord_cartesian(clip="off") +
  theme(axis.ticks = element_blank(),
        axis.title = element_blank(),
        axis.text.y=element_blank(),
        # x轴文本上移
        axis.text.x=element_text(
          angle = 45,color="black",vjust=1,hjust=1,
          margin = margin(t=-1.8,unit="cm")),
        plot.margin = margin(0,0,0,1,unit="cm"),
        panel.background = element_blank(),
        legend.title = element_blank(),
        legend.key.height = unit(1,"null"),
        legend.position = "right")
# 拼图
(p2|p1|p3)+plot_layout(widths = c(1,2,1.5))