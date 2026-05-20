library(tidyverse)
library(grid)
library(ggsankeyfier) 
library(magrittr)
library(RColorBrewer)

sessionInfo()

df <- read_tsv("sankey_data.tsv")

# 按层级进行数据格式转换
df1 <- df %>% slice(1:5) %>% pivot_stages_longer(
  .,stages_from = c("type1", "type2"),values_from = "counts")

df2 <- df %>% slice(6,18) %>% 
  set_colnames(c("type2","type3","counts")) %>% 
  pivot_stages_longer(
  .,stages_from = c("type2", "type3"),values_from = "counts")

df3 <- df %>% slice(7:17) %>% 
  set_colnames(c("type3","type4","counts")) %>% 
  pivot_stages_longer(
  .,stages_from = c("type3","type4"),values_from = "counts")
# 定义属性
pos <- position_sankey(
  width = 0.1,order = "as_is",v_space ="auto")

ggplot(data=df1,aes(x = stage,y =counts,group = node,
                    edge_id = edge_id,connector = connector)) +
  geom_sankeynode(aes(fill=node),color="black",position = pos) +
  # 绘制第 1，2 层级
  geom_sankeyedge(aes(fill=node),position = pos) +
  geom_text(data= df1 %>% filter(connector=="from"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",nudge_x=0.1),
            hjust=0,size=3.5) +
  # 绘制第 2，3 层级
  geom_sankeynode(data=df2,aes(fill=node),color="black",position = pos) +
  geom_sankeyedge(data=df2,aes(fill = node),position = pos) +
  # 绘制第 3，4 层级
  geom_sankeynode(data=df3,aes(fill=node),color="black",position = pos) +
  geom_sankeyedge(data=df3,aes(fill = node),position = pos)  +
  # 添加各层文本
  geom_text(data=df2 %>% filter(connector=="from"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",nudge_x=0),
            hjust=0.5,size=3,angle=90,color="white",fontface = "bold") +
  geom_text(data=df2 %>% filter(connector=="to"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",nudge_x=0),
            hjust=0.5,size=3,angle=90,color="white",fontface = "bold") +
  geom_text(data=df3 %>% filter(connector=="to"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",
              nudge_x=0.1),hjust=0,size=3.5) +
  coord_cartesian(clip="off")+
  scale_x_discrete(position = "bottom")+
  scale_fill_manual(values =colorRampPalette(brewer.pal(12,"Paired"))(19)) +
  theme_void() +
  theme(plot.margin = margin(0,1.5,1,0,unit = "cm"),
        axis.text.x=element_blank(),
        legend.position="none")

