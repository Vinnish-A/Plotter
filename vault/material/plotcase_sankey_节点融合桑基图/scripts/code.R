library(tidyverse)
library(ggsankeyfier)
library(magrittr)
library(RColorBrewer)

sessionInfo()

df <- read_tsv("data1_1.tsv")
# 将不同层级间的数据拆为2份
df1 <- df %>% slice(1:20) %>% 
  pivot_stages_longer(.,stages_from = c("Source", "Target"),
                      values_from = "Value")

df2 <- df %>% slice(21:n()) %>% 
  set_colnames(c("Target","Bacteria","Value")) %>% 
  pivot_stages_longer(.,stages_from = c("Target", "Bacteria"),
                      values_from = "Value") %>% 
  mutate(stage=factor(stage,levels = c("Target","Bacteria")))
# 按上面思路所述将第2-3层级中的Target节点数值与1-2层级中的Target节点融合
v1 <- df2 %>% filter(connector=="from") %>% select(1,4) %>% 
  group_by(node) %>% 
  mutate(sum=sum(Value)) %>% select(2,3) %>% ungroup() %>% distinct() %>% 
  mutate(Value=sum,edge_id=c(21,22,23,24),
         connector="to",stage="Target") %>% select(3,4,5,1,6)

v2 <- df1 %>% filter(connector=="to") %>% select(1,4) %>%
  group_by(node) %>%
  mutate(sum=sum(Value)) %>% select(2,3) %>% ungroup() %>% distinct() %>%
  mutate(Value=sum)
# 定义桑基图属性
pos <- position_sankey(width = 0.05,v_space =4,align = "bottom")
# 融合数据
dff1 <- df1 %>% bind_rows(v1 %>% mutate(Value=v1$Value-v2$Value)) %>% 
  mutate(stage=factor(stage,levels = c("Source","Target")))

ggplot(data=dff1,aes(x = stage,y =Value,group = node,
                     edge_id = edge_id,connector = connector,fill=node))+
  # 添加边属性
  geom_sankeyedge(position = pos) +
  # 添加点属性
  geom_sankeynode(color="white",position = pos)+
  # 添加文本
  geom_text(data=dff1 %>% filter(connector=="from"),aes(label = node),
            stat = "sankeynode",
            position = position_sankey(v_space =4),
            hjust=1.2,size=2.5) +
  geom_text(data=dff1 %>% filter(connector=="to"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(v_space=4,nudge_x = -0.01),
            hjust=1.5,size=3) +
  # 第2-3层级
  geom_sankeyedge(data=df2,position = pos) +
  geom_sankeynode(data=df2,color="white",position = pos) +
  geom_text(data=df2 %>% filter(connector=="to"),aes(label = node),
            stat = "sankeynode",
            position = position_sankey(v_space=4,nudge_x = 0.03),
            hjust=0,size=2.5) +
  # 定义颜色
  scale_fill_manual(values = colorRampPalette(brewer.pal(12,"Paired"))(24)) +
  theme_void() +
  theme(legend.position = "none")