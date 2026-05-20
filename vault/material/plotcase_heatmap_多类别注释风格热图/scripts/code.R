library(tidyverse)
library(legendry)

sessionInfo()

# 数据整合
df <- read_tsv("data.tsv") %>% 
  pivot_longer(-c("type","sample")) %>% 
  left_join(.,read_tsv("group.tsv"),by=c("name"="gene")) %>% 
  mutate(sample=as.factor(sample))

df %>% ggplot(.,aes(interaction(name,group),
                    interaction(sample,type),fill=value)) +
  geom_tile() +
  scale_fill_gradient2(low = "#1f3a93",mid = "white",high = "#c0392b",
    midpoint = 0.5,limits = c(0,1),name = NULL) +
  guides(y = legendry::guide_axis_nested(
    key = key_range_auto(sep = "\\."),
    levels_text = list(
      element_blank(), # 内层文本隐藏
      # 外层分组文本
      element_text(angle = 90,size=10,face = "bold",
                   vjust=0.5,hjust=0.5,
                   color=c("#A6CEE3","#CAB2D6"))),
    # 设置线条颜色
    levels_brackets=list(
      element_line( # 内层线条颜色
        color=c("#A6CEE3","#CAB2D6"),linewidth = 1))),
    # X轴将分面条带转化为盒子的风格
    x = legendry::guide_axis_nested(
      type="box",
      position="top", # 位于顶部
      key = key_range_auto(sep = "\\."),
      # 若一组只有一个数据，设为 FALSE以避免该分组被隐藏
      drop_zero = FALSE, 
      pad_discrete = 0.4, # 设置为0.5则没有间距
      levels_text = list(
        element_blank(), # 内层文本隐藏
        element_text(color="white",face="bold",size=10,vjust = 0.5)),
      levels_box=list(element_rect(fill=c("#ef6a8a","#e6a94b","#CAB2D6"),
                                   color="grey40")))) +
  # 通过添加辅助轴来显示底部的文本
  scale_x_discrete(sec.axis = dup_axis(
    labels = unique(df$name))) +
  theme(axis.ticks = element_blank(),
        axis.title = element_blank(),
        axis.text.x.bottom = 
          element_text(color="black",angle = 90,vjust = 0.5,hjust=1,size=8),
        legend.key.height = unit(1,"null"),
        legend.ticks = element_line(color="black"),
        legend.frame = element_rect(color="black"))
