library(tidyverse)
library(legendry)
library(ggtext)

df <- read_tsv("data.tsv")

df %>% pivot_longer(-c(Subtype.x,Subtype.y,Sample_id)) %>% 
  ggplot(aes(interaction(Sample_id,Subtype.x,Subtype.y),
             value,fill=name))+
  geom_col(position="stack")+
  scale_fill_manual(values = c("#CAB2D6","#A6CEE3","#33A02C"))+
  labs(x=NULL, y="Relative percent")+
  scale_y_continuous(expand = c(0,0),labels=scales::percent)+
  # 嵌套注释
  guides(x = legendry::guide_axis_nested(
     type="box",
     min_size=unit(0,"cm"),
     pad_discrete = 0.5,
     key = key_range_auto(sep = "\\."),
     drop_zero = FALSE, # 若一组只有一个数据则要定义为F
     # 文本属性
     levels_text = list(
       element_blank(), # x轴文本
       element_markdown(color="black",size=10), # 内层文本
       element_markdown(color="black",size=10)), # 外层文本
     # 边框属性
     levels_box=list(element_rect(  # 外层边框填充色
        fill=c("#FB9A99","#FDBF6F","#FF7F00","#CAB2D6"),color="white"),
        element_rect( # 内层边框  
          fill=c("#A6CEE3","#33A02C"),color="white")))) +
  theme(axis.ticks.x=element_blank(),
        axis.text.y=element_text(color="black"),
        legend.title = element_blank())