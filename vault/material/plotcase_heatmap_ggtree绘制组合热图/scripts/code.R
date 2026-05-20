library(tidyverse)
library(ggtree)
library(aplot)

sessionInfo()

color <- c("grey70","#709AE1FF")

heatmap <- read_tsv("data.txt") %>% select(-1) %>% pivot_longer(-Gene) %>% 
  mutate(type=case_when(value==0  ~ "Absence",value==1 ~ "presence")) %>% 
  ggplot(aes(Gene,name,fill=type))+
  geom_tile(fill="white",size=0.5)+
  geom_point(pch=22,size=5)+
  labs(x = NULL,y = NULL,color=NULL)+
  scale_color_manual(values=color)+
  scale_fill_manual(values=color)+
  scale_x_discrete(expand=c(0,0))+ 
  theme(axis.text.x=element_text(color="black",angle=90,size=8,hjust=1,vjust=0.5),
        axis.text.y=element_blank(),
        axis.ticks.x=element_blank(),
        axis.ticks.y=element_blank(),
        panel.border=element_rect(fill=NA,color="black",linewidth=0.8,linetype="solid"),
        legend.title = element_blank(),
        legend.background = element_blank(),
        legend.key = element_blank(),
        plot.margin=unit(c(0.2,0.2,0.2,0.2),units=,"cm"))

df <- read_tsv("data.txt") %>% select(-1) %>% 
  column_to_rownames(var="Gene") %>% 
  t() %>% as.data.frame()

group <- read_tsv("group.txt")

phr <- hclust(dist(df,method="euclidean"),method="complete") %>% 
  ggtree(layout="rectangular",branch.length="none") %<+% group+
  geom_tippoint(aes(shape = Group,color = Group),size=3)+
  theme(legend.title = element_blank(),legend.key = element_blank(),
        legend.text = element_text(color="black",size=10))
  
phc <- hclust(dist(t(df),method="euclidean"),
              method="complete") %>% ggtree() + layout_dendrogram()

heatmap %>% insert_left(phr, width=.6) %>% insert_top(phc, height=0.08) 

