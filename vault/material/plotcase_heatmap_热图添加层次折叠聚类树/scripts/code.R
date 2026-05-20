library(tidyverse)
library(ggtree)
library(aplot)
library(RColorBrewer)

sessionInfo()

df <- read_csv("Figure5-metabolicfunctions_logtpm.csv") %>% 
  dplyr::rename(tax=`...1`) %>% 
  column_to_rownames(var="tax")

# 根据此基础图确定要折叠的节点信息，也就是下方代码中的数字
hclust(dist(df)) %>% ggtree() +
  geom_text(aes(label=node),size=3,color="red",vjust=0)
# 绘制折叠聚类树
tree <- hclust(dist(df)) %>% 
  ggtree(branch.length="none") %>% 
  collapse(174, 'min', fill="#E41A1C")  %>% 
  collapse(173, 'max', fill="#1E90FF") %>% 
  collapse(146, 'mix', fill="#FF8C00") %>% 
  collapse(141, 'mixed', fill="#4C005C") %>% 
  collapse(155, 'min', fill="#003380") %>% 
  collapse(154, 'min', fill="#FF8C00") %>%
  collapse(155, 'min', fill="#FF8C00") %>%
  collapse(152, 'mixed', fill="#740AFF") %>%
  collapse(151, 'min', fill="#FF8C00") %>% 
  collapse(150, 'min', fill="#8F7C00") %>% 
  collapse(143, 'min', fill="#E41A1C") %>% 
  collapse(144, 'min', fill="#94FFB5") %>% 
  collapse(159, 'min', fill="#0075DC") %>% 
  collapse(158, 'min', fill="#00FFFF") %>% 
  collapse(156, 'min', fill="#E41A1C") %>% 
  collapse(148, 'min', fill="#8F7C00") %>% 
  collapse(140, 'min', fill="#E41A1C")


df2 <- read_csv("Figure5-metabolicfunctions_logtpm.csv") %>% 
  dplyr::rename(tax=`...1`) %>% 
  pivot_longer(-tax)
# 将折叠的聚类树图与热图组合，其绘制思路为先单独绘图后拼图。
heatmap <- df2 %>% ggplot(aes(name,tax,fill=value))+
  geom_tile()+
  labs(x=NULL,y=NULL)+
  scale_y_discrete(expand=c(0,0),position="left")+
  scale_x_discrete(expand=c(0,0))+
  scale_fill_gradientn(colours = colorRampPalette(rev(brewer.pal(n = 6, name ="RdYlBu")))(100))+
  theme(axis.text.x=element_text(color="black",angle=90,vjust=0.5,size=8,hjust=1),
        axis.text.y=element_blank(),
        axis.ticks = element_blank(),
        legend.title = element_blank(),
        legend.text = element_text(size=8,color="black"))+
  guides(fill=guide_colorbar(direction = "vertical",
  reverse = F,barwidth = unit(.6, "cm"),
                             barheight = unit(13,"cm"))) 
# 拼图
heatmap %>% insert_left(tree,width = c(1,4))
