library(tidyverse)
library(magrittr)
library(geomtextpath)
library(MetBrewer)

sessionInfo()
# 定义group顺序与1,2,3数值进行对应
df <- read_tsv("data.tsv") %>%
  mutate(Group = factor(Group, levels = c(
    "Inflammation", "Mitochondrion", "Proteostasis",
    "Cellular senescence", "Cell communication",
    "Transcription regulation"))) %>%
  arrange(Group) %>% 
  set_colnames(c("Term","Group","RNA expression",
                 "NCIN capping","P_value")) %>% 
  mutate(id=row_number()) %>% 
  mutate(id=as.factor(id)) 
# 计算一下分组标签的位置信息
df_x <- df %>%  select(2,id) %>% 
  mutate(id=as.numeric(id)) %>% 
  group_by(Group) %>% 
  mutate(x=(max(id)+min(id))/2) %>% 
  select(1,3) %>% distinct()

df %>% select(2,3,4,id,P_value) %>% 
# p值转换
  mutate(P_value = 
           str_extract(P_value,"(?<=p-value = )[0-9.]+") %>% 
           as.numeric()) %>% 
  mutate(sig = case_when(
    P_value <= 0.001 ~ "***",
    P_value <= 0.01  ~ "**",
    P_value <= 0.05  ~ "*",TRUE ~ NA)) %>% 
  select(1,2,3,4,6) %>% 
  pivot_longer(-c(id,Group,sig)) %>% 
  ggplot(aes(id,value)) +
  # 添加背景色
  geom_rect(aes(xmin=0.5,xmax=5.5,ymin=-3,ymax=Inf),fill="#FBECDC") +
  geom_rect(aes(xmin=5.5,xmax=8.5,ymin=-3,ymax=Inf),fill="#FDE2E2") +
  geom_rect(aes(xmin=8.5,xmax=15.5,ymin=-3,ymax=Inf),fill="#D9F1E3") +
  geom_rect(aes(xmin=15.5,xmax=18.5,ymin=-3,ymax=Inf),fill="#FAD4D4") +
  geom_rect(aes(xmin=18.5,xmax=23.5,ymin=-3,ymax=Inf),fill="#EAE8FB") +
  geom_rect(aes(xmin=23.5,xmax=26.5,ymin=-3,ymax=Inf),fill="#E0F3FB") +
  # 添加连接线
  geom_line(aes(group = id), color = "gray80", linewidth = 1) +
  # 添加水平虚线
  geom_hline(aes(yintercept =0),color = "black",linewidth = 0.5,
             linetype=2) +
  # 添加点
  geom_point(aes(shape=name,fill=value),size=4) +
  # 添加垂直分割线
  geom_vline(xintercept = c(5.5,8.5,15.5,18.5,23.5,0.5),
             color="white",linewidth=1) +
  # 添加文本 1，2，3
  geom_textpath(aes(label = id, y = 2),vjust=1.2)+
  # 添加p值，用星表示
  geom_textpath(aes(label = sig, y = 4.5),vjust=0,size=5,color="red") +
  # 添加分组文本
  geom_textpath(data=df_x,aes(label = Group, y = 5.5,x=x),
                inherit.aes = F,vjust=0) + 
  # 添加第二圈白色水分分割线
  geom_rect(aes(xmin=-Inf,xmax=Inf,ymin=3,ymax=3.15),fill="white") +
  scale_y_continuous(expand= expansion(mult = c(0.2,0.15))) +
  scale_x_discrete(expand= expansion(mult = c(0,0))) +
  scale_fill_gradientn(colors=met.brewer("VanGogh2")) +
  # 极坐标化
  coord_radial(start =0,end =2*pi,
               inner.radius = 0.3,clip="off") +
  scale_shape_manual(values = c(24,21))+
  labs(fill="Pathway score",shape=NULL) +
  guides(fill=guide_colourbar(position = "inside",
                              barwidth=unit(6,"cm"),
                              barheight=unit(0.5,"cm")),
         shape=guide_legend(position = "inside")) +
  theme(axis.text=element_blank(),
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        plot.background = element_blank(),
        panel.background = element_blank(),
        legend.direction = "horizontal",
        legend.title.position = "top",
        legend.title=element_text(hjust=0.5),
        legend.background = element_blank())