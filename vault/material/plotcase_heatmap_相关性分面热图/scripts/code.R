library(tidyverse)
library(reshape)
library(psych)
library(RColorBrewer)
library(magrittr)
library(ggh4x)

table1 <- read.delim("env.tsv",header =T,
                     sep="\t",row.names = 1,check.names = F)

table2 <- read.delim("genus.tsv",header =T,
                     sep="\t",row.names = 1,check.names = F) %>% 
  t() %>% as.data.frame()

pp <- corr.test(table1,table2,method="pearson",adjust = "none")

cor <- pp$r
pvalue <- pp$p

df <- melt(cor) %>% mutate(pvalue=melt(pvalue)[,3],
                           p_signif=symnum(pvalue, corr = FALSE, na = FALSE,  
                                           cutpoints = c(0, 0.001, 0.01, 0.05,1), 
                                           symbols = c("***", "**", "*", " "))) %>% 
  set_colnames(c("env","genus","r","p","p_signif"))

# 定义分面背景颜色
ridiculous_strips <- strip_themed(
  background_y = elem_list_rect(
    fill =  c("#DE9ED6FF","#709AE1FF","#D2AF81FF"))
)

df %>% left_join(.,read_tsv('annotation.tsv'),by=c("genus")) %>% 
  ggplot(.,aes(env,genus))+
  geom_tile(color="grey40",fill="white",linewidth=0.4)+
  geom_point(aes(size =abs(r),fill=r,color=r),shape=21) +
  geom_text(aes(label=p_signif),size=4,color="white",hjust=0.5,vjust=0.7)+
  facet_grid2(group~.,scale="free_y",
              switch = "y",
              strip = ridiculous_strips)+
  labs(x = NULL,y = NULL,fill=NULL,
       color="Pearson \n correlation") +
  scale_fill_gradientn(colours = rev(RColorBrewer::brewer.pal(11,"RdBu")),
                        guide=guide_colorbar(direction="vertical",reverse=F,
                                             order = 0,barheight=unit(12,"cm"))) +
  scale_color_gradientn(colours = rev(RColorBrewer::brewer.pal(11,"RdBu")),
                        guide = "none") +
  scale_x_discrete(labels=c("NH4+"=expression(NH[4]^+""),
                            "NO2--"=expression(NO[2]^-""),
                            "CuSO4"=expression(CuSO[4])))+
  scale_y_discrete(expand=c(0,0),position = 'right') +
  scale_size(range=c(1,10),guide=NULL) +
  theme(axis.text.x=element_text(
    angle =45,hjust =1,vjust =1,color="black",size = 10),
        axis.text.y=element_text(color="black",size =10),
        axis.ticks= element_blank(),
        panel.spacing.y = unit(0,"cm"),
        panel.background = element_blank(),
        legend.background = element_blank()) 


