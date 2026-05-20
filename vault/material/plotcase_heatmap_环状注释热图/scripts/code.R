library(tidyverse)
library(ggtree)
library(treeio)
library(ape)
library(ggnewscale)
library(ggtreeExtra)

sessionInfo()

df <- read_tsv("data.tsv")

species <- df$sample
newick_string <- paste("(", paste(species, collapse = ","), ");", sep = "")
tree <- read.tree(text = newick_string)
expdata <- df %>% select(-Group) %>% pivot_longer(-sample)
group <- df %>% select(sample,Group) %>% mutate(group="group")

ggtree(tree,branch.length = "none", layout = "circular",linetype = 0,size = 0.5) +
  layout_fan(angle =60)+  
  geom_fruit(data=expdata,geom=geom_tile,
             mapping=aes(y=sample,x=name,fill=value),
             pwidth=2,offset=0.01,
             axis.params=list(axis="x",text.angle=-90,text.size=3,hjust=0))+
  scale_fill_gradientn(colours = rev(RColorBrewer::brewer.pal(11,"RdBu"))) +
  geom_tiplab(offset=2.3,size=2.5,color = "black")+
  new_scale_fill()+
  geom_fruit(data=group,geom=geom_tile,
             mapping=aes(y=sample,x=group,fill=Group),
             pwidth=0.2,offset=0.6)+
  scale_fill_manual(values=c("#85D4E3","#7294D4","#C18748"))

