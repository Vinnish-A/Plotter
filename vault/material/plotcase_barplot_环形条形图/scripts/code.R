library(tidyverse)
library(geomtextpath)

df <- read_tsv("data2.tsv") %>% group_by(Group) %>%
  slice_min(`p value`, n = 5, with_ties = FALSE) %>% 
  ungroup() %>% 
  mutate(id=as.factor(row_number())) %>% as.data.frame()

seg_df <- df %>% group_by(Group) %>%
  summarise(start_id = first(id),end_id   = last(id))

df %>% ggplot(.,aes(id,-log10(`p value`),fill=Group)) + 
  geom_bar(stat="identity") +
  geom_segment(y=0,yend=0,x=0,xend=44,linetype = 1,linewidth=0.4) +
  geom_textpath(aes(label = Pathway),size=3,spacing = 40,
                angle=90,vjust=0.5,hjust=-0.1) +
  geom_segment(data=seg_df,aes(x=start_id,xend=end_id,y=7.2,yend=7.2),
               linewidth = 0.8)+
  geom_textpath(data=df %>% filter(id %in% c(3,8,12,17,22,27,32,37,42)),
                aes(x=id,label =Group,y=7.8,color=Group),inherit.aes = F,
                size=4,angle=0,vjust=0.5,hjust=0.5) +
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_manual(values = c( "#9C545C","#E36C61","#D7B6A6","#4E79D9","#B455E4", "#F041A9",
                                "#6F7FAF","#50648A","#6E6E72")) +
  scale_color_manual(values = c( "#9C545C","#E36C61","#D7B6A6","#4E79D9","#B455E4", "#F041A9",
                                "#6F7FAF","#50648A","#6E6E72")) +
  coord_radial(start =0, end =1.94*pi,inner.radius = 0.35,clip="off") +
  theme_bw() +
  theme(legend.position = 'none',
        panel.background = element_blank(),
        plot.background = element_blank(),
        panel.border = element_blank(), 
        axis.text.y=element_text(color="black"),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.title = element_blank()) 
