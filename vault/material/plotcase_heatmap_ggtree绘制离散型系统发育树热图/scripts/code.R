library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(ggnewscale)

sessionInfo()

tree <- read.tree("RAxML_bipartitions.allUK_1000.nwk")

cir <- ggtree(tree, layout="circular")+
  geom_tiplab(size=2,align=T,linesize=0,color="black",offset =0.4)

df <- read_csv("metadata.csv") %>%
  column_to_rownames(var="label")

p1 <- gheatmap(cir,df %>% select(1),offset=0.6,width=.1,
               colnames_offset_y=0,colnames = F,color=NULL)+
  scale_fill_manual(values=c("#440154","#3b528b"))+
  new_scale_fill()

gheatmap(p1,df %>% select(2),offset=0.696,width=.1,
           colnames_offset_y=0,colnames = F,color=NULL)+
  scale_fill_manual(values=c("#21918c","#5ec962","#fde725"))+
  theme(legend.title = element_blank(),
        legend.text=element_text(color="black"),
        legend.background = element_blank(),
        legend.key = element_blank(),
        legend.spacing.x = unit(0.1,'cm'),
        legend.key.width=unit(0.4,'cm'),
        legend.key.height=unit(0.4,'cm'))

  
