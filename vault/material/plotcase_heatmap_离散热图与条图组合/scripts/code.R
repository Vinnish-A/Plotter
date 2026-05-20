library(tidyverse)
library(readxl)
library(patchwork)
library(legendry)

sessionInfo()

df <- read_excel("41467_2022_35431_MOESM8_ESM.xlsx",sheet = 4)
df$ID <- factor(df$ID,levels = df$ID %>% unique())

p1 <- df %>% ggplot(aes(x=ID,y=`Pathological regression (%)`,
                  fill=group))+geom_col()+
  scale_y_continuous(expand = c(0,0))+
  scale_x_discrete(expand = c(0,0))+
  scale_fill_manual(name="Response",
                    values=c("#FABE01","#74C6BC"))+
  geom_hline(yintercept=c(-50,-75,-90),
             linetype="dashed",color="grey")+
  theme_test()+
  theme(axis.title.y = element_text(color="black"),
        axis.title.x = element_blank(),
        axis.ticks.x=element_blank(),
        plot.margin = unit(c(0,0,0,0),unit="cm"),
        axis.text = element_text(color="black",size=8))
  
df2 <- df %>% select(1:7) %>% pivot_longer(-ID) %>% 
  mutate(sign=case_when(value =="NA" ~ "X",TRUE ~ " ")) %>% 
  mutate(values = paste0(name," ",value))
  
df2$name <- factor(df2$name,levels = df2$name %>% unique() %>% rev())

lev <- df2 %>% distinct(name,values,value) %>% arrange(name) %>% 
  filter(value !="NA") %>% 
  mutate(col=c("#842064","#E8E166", "#842064","#E8E166",
               "#080922","#C64543","#080922","#C64543",
               "#080922","#C64543","#080922","#C64543"))

col <- lev %>% select(values,col) %>% deframe()
lut <- key_group_lut(lev$values,lev$name)

p2 <- df2 %>% ggplot(aes(ID,name,fill=paste(name,values)))+
  geom_tile(color=NA,width=.9,height=.9,aes(fill=values))+
  geom_text(aes(label=sign),size=8)+
  guides(fill = guide_legend_group(key = lut,title=NULL,ncol =1)) +
  scale_y_discrete(expand = c(0,0))+
  scale_x_discrete(expand = c(0,0))+
  scale_fill_manual(values =col,na.value = "white",
                  breaks = lev$values,
                  labels= lev$value) +
  theme(axis.title = element_blank(),
        axis.text.x=element_blank(),
        axis.text.y=element_text(color="black"),
        axis.ticks=element_blank(),
        plot.background = element_blank(),
        panel.background = element_blank(),
        legend.spacing.x=unit(0.1,'cm'),
        legend.key.width=unit(0.5,'cm'),
        legend.key.height=unit(0.5,'cm'),
        legend.text = element_text(color="black",size=8))  

(p2/free(p1,type="label"))+
  plot_layout(ncol=1,heights = c(0.4,0.8)) +
  plot_layout(guides = 'collect')

