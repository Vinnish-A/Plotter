library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(treeio)

sessionInfo()

df <- read_tsv("data.tsv") %>% pivot_longer(-gene) %>% 
  mutate(group=case_when(value == 0 ~ "not regulated",
                         name=="CNA" & value== 1 ~ "CNA (direct)",
                         name=="mir" & value== 1 ~ "miRNA (inverse)",
                         name=="methylationpromoter" & value==1 ~ "methylation (direct)",
                         name=="methylationgenebody" & value==1 ~ "methylation (direct)",
                         name=="methylationanywhere" & value==1 ~ "methylation (direct)",
                         name=="methylationpromoter" | name=="methylationgenebody" | name=="methylationanywhere" | 
                         value == -1 ~ "methylation (inverse)"))

df$group <- factor(df$group,levels = c("CNA (direct)","miRNA (inverse)",
                                       "methylation (inverse)",
                                       "methylation (direct)","not regulated"))

df$name <- factor(df$name,levels = rev(c("methylationgenebody","methylationanywhere",
                                         "methylationpromoter",
                                     "mir","CNA")))


hclust(dist(read_tsv("data.tsv") %>% 
              column_to_rownames(var="gene"))) %>% 
  ggtree(layout="fan", open.angle=20, size=0.3) %>% 
  rotate_tree(.,angle=0)+
  geom_tiplab(size=3,color="black",offset=1)+
  geom_fruit(data=df, geom=geom_tile,
             mapping=aes(y=gene,x=name,fill=group),
             color = "black",offset = 0.03,size = 0.1)+
  scale_fill_manual(values=c("#5686C3","#973CB6","#F5A300","#75C500","#D9D9D9"))+
  theme(legend.background = element_blank(),
        legend.title = element_blank())






