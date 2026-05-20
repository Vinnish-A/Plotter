library(tidyverse)
# install.packages("geomtextpath")
library(geomtextpath)
library(corrplot)

sessionInfo()

# 数据读取
mat1 <- read_tsv("heatmap.tsv")
group <- read_tsv("group2.tsv")
# 整合数据
df <- mat1 %>% 
  left_join(.,group,by="id") %>% 
  pivot_longer(-c(id,group))

df %>% ggplot(aes(id,y=name,fill=value))+
  geom_tile(color="white",linewidth = 1)+
  scale_fill_gradientn(colors=rev(COL2('PRGn',100)),na.value = "white")+
  scale_x_discrete(expand = c(0,0))+
  scale_y_discrete(expand = c(0,0))+
  # 添加X轴文本
  geom_textpath(aes(label = id, y = 5),size=4,parse = TRUE)+
  # 极坐标化
  coord_radial(start =0.02, end =pi*2, inner.radius = 0.6) +
  # 添加内部数值文本
  geom_textpath(data=df,aes(x=id,y=name,label = round(value,digits = 2)),size=3) +
  # 添加外圈分组条带
  geom_rect(aes(xmin=0.21,ymin=6,xmax=4.48,ymax=6),linewidth =7,color="#D9D0D3")+
  geom_rect(aes(xmin=16.5,ymin=6,xmax=20.48,ymax=6),linewidth =7,color="#7294D4")+
  geom_rect(aes(xmin=11.5,ymin=6,xmax=16.48,ymax=6),linewidth =7,color="#C6CDF7")+
  geom_rect(aes(xmin=7.5,ymin=6,xmax=11.48,ymax=6),linewidth =7,color="#78B7C5")+
  geom_rect(aes(xmin=4.5,ymin=6,xmax=7.48,ymax=6),linewidth =7,color="#85D4E3")+
  # 添加分组文本
  geom_textpath(size =4.8, hjust = 0.5,label="Plant(PL)",x=2.5,y=6.1) +
  # 对数据标记
  geom_tile(data=df %>% filter(id=="R5",name=="C1"),
            aes(id,name),color="red",fill=NA,inherit.aes = F,linewidth = 0.5) +
  # 定义图例属性
  guides(fill= guide_colorbar(position = "inside",
                              barwidth=unit(8,"cm"),
                              barheight=unit(0.5,"cm"))) +
  theme(axis.text=element_blank(),
        axis.title = element_blank(),
        axis.ticks = element_blank(),
        panel.background = element_blank(),
        axis.text.r = element_text(colour="black",size=10,
                                   margin=margin(r=-0.5,unit = "cm")),
        legend.title = element_blank(),
        legend.background = element_blank(),
        legend.direction="horizontal")

