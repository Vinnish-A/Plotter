library(tidyverse)
library(grid)
library(ggsankeyfier) 
library(ggnewscale)

sessionInfo()

df <- read_tsv("data.tsv")
# 转化数据格式
df1 <- df %>% select(1,2) %>% group_by(Locations,`Resistance types`) %>% count() %>%
  pivot_stages_longer(.,stages_from = c("Locations", "Resistance types"),
                      values_from = "n")
df2 <- df %>% select(2,3) %>% group_by(`Resistance types`,`Novel ARGs`) %>% count() %>%
  pivot_stages_longer(.,stages_from = c("Resistance types", "Novel ARGs"),
                      values_from = "n")

df3 <- df %>% select(3,4) %>% group_by(`Novel ARGs`,Pathogens) %>% count() %>%
  pivot_stages_longer(.,stages_from = c("Novel ARGs","Pathogens"),
                      values_from = "n")
# 构建渐变色
patterns1 <- replicate(nrow(df1), linearGradient(
  colours = c("#859B6C99", "#F28AAA99"),
  stops = c(0, 1), x1 = 0, y1 = 0.5,
  x2 = 1, y2 = 0.5, group = FALSE), simplify = FALSE)

patterns2 <- replicate(nrow(df2), linearGradient(
  colours = c("#F28AAA99", "#87CEEBE6"),
  stops = c(0,1), x1 = 0, y1 = 0.5,
  x2 = 1, y2 = 0.5, group = FALSE), simplify = FALSE)

patterns3 <- replicate(nrow(df3), linearGradient(
  colours = c("#87CEEBE6", "#dfbbca"),
  stops = c(0,1), x1 = 0, y1 = 0.5,
  x2 = 1, y2 = 0.5, group = FALSE),simplify = FALSE)
# 自定义颜色
col <- c("Antarctic"="#859b6c","Arctic"="#859b6c",
         "Penicillin G"="#f28aaa","Ticarcillin"="#f28aaa",
          "k149_13756_1"="skyblue","k149_8113_1"="skyblue",
          "k149_8894_1"="skyblue","k149_957_1"="skyblue",
          "k149_7801_1"="skyblue",
         "Klebsiella pneumoniae subsp. pneumoniae HS11286"="#c7a2b6",
         "Providencia stuartii strain CAVP490"="#c7a2b6",
         "Escherichia fergusonii strain FDAARGOS_1499"="#c7a2b6",
         "Proteus penneri strain S178-2"="#c7a2b6",
         "Shigella boydii strain"="#c7a2b6",
         "Shigella dysenteriae strain SWHEFF_49"="#c7a2b6")

pos <- position_sankey(width = 0.05,
                       order = "as_is",v_space ="auto")

ggplot(data=df1,aes(x = stage,y =n,group = node,
                    edge_id = edge_id,connector = connector)) +
  geom_sankeynode(aes(fill=node),
                  position = pos)+
  scale_fill_manual(values = col) +
  new_scale_fill()+
  # 绘制第 1，2 层级
  geom_sankeyedge(aes(fill = patterns1),position = pos) +
  new_scale_fill()+
  geom_text(aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",nudge_x=-0.05),
            hjust=1,size=3.5) +
  # 绘制第 2，3 层级
  geom_sankeynode(data=df2,aes(fill=node), position = pos) +
  scale_fill_manual(values = col)+
  new_scale_fill()+
  geom_sankeyedge(data=df2,aes(fill = patterns2),position = pos) +
  new_scale_fill()+
  geom_text(data=df2 %>% filter(connector=="to"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(v_space ="auto",nudge_x=-0.05,
                                       order="as_is"),
            hjust=1,size=3.5) +
  # 绘制第 3，4 层级
  geom_sankeynode(data=df3,aes(fill=node),position = pos)+
  scale_fill_manual(values = col)+
  new_scale_fill()+
  geom_sankeyedge(data=df3,aes(fill = patterns3), position = pos)+
  # 添加文本
  geom_text(data=df3 %>% filter(connector=="to"),
            aes(label = node),stat = "sankeynode",
            position = position_sankey(
              v_space ="auto",order="as_is",
              nudge_x=-0.1),hjust=0.5,size=3.5)+
  coord_cartesian(clip="off")+
  scale_x_discrete(position = "bottom")+
  theme_void()+
  theme(plot.margin = margin(0.5,1,1,0,unit = "cm"),
        axis.text.x=element_text(
          color="black",face="bold",size=12,
          margin = margin(b=-0.5,unit = "cm")),
        legend.position="none")