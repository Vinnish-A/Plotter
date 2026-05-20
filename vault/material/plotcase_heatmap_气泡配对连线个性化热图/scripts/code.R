library(tidyverse)
library(ggnewscale)
library(patchwork)
library(RColorBrewer)

sessionInfo()
# 数据读取，读入两份数据
df1 <- read_tsv("heatmap1.tsv") %>% pivot_longer(-c(Gene,id)) %>% 
  mutate(Percent = runif(n(), 0, 100))

df2 <- read_tsv("heatmap2.tsv") %>% 
  pivot_longer(-c(Gene,id)) %>% 
  mutate(Percent = runif(n(), 0, 100)) %>% mutate(value=as.character(value))
# 整合数据
dff <- df1 %>% bind_rows(df2) %>% 
  mutate(id=factor(id,levels = rev(unique(id))))

dff$name <- factor(dff$name,levels = unique(dff$name))

p1 <- dff %>% ggplot(.,aes(name,id)) +
# 拆分数据添加气泡
  geom_point(data=dff %>% filter(id %in% as.character(14:32)) %>% 
               mutate(value=as.numeric(value)),
             aes(fill=value,size=Percent),pch=21) +
  scale_fill_gradientn(
    colours = rev(colorRampPalette(brewer.pal(11, "RdBu")[3:9])(200))) +
  new_scale_fill() +
   # 用于留白
  geom_point(data=dff %>% filter(id %in% as.character(13)),
             aes(fill=value),pch=22,size=0,stroke = 0,show.legend = F) +
  new_scale_fill() +
  geom_point(data=dff %>% filter(id %in% as.character(1:12)) %>% 
               mutate(value=as.numeric(value)),
             aes(fill=value,size=Percent),pch=21,show.legend = F) +
  scale_fill_gradientn(
    colours = rev(colorRampPalette(brewer.pal(11, "RdBu")[3:9])(200))) +
    # 替换标签
  scale_y_discrete(label=rev(c("GZMA","CD6","C5","MIF","ALCAM","SEMA4A","LGALS9","SEMA4D",
                           "GUCA2A","F11R","CDH1","APP","Tissues",
                           "PARD3","F2R","ALCAM","C5AR1","C3AR1","HAVCR2","CXCR4",
                           "CR2","ITGB7","ITGAE","ITGB2","ITGAL","CD6",
                           "CD44","PLXNB2","GUCY2C","F11R","CDH1","CD74")),
                   position = "right") +
   # 添加边框
  geom_vline(xintercept = c(0.5,20.5)) +
  geom_hline(yintercept = c(0.5,32.5)) +
  theme_void() +
  theme(axis.text.y=element_text(size=9,
    color=c(rep("black",19),"white",rep("black",12))),
        legend.background = element_blank(),
        legend.position = "left",
        panel.grid = element_line(color="grey90"))
# 点线图
# 定义线段的位点信息
df_curve <- data.frame(x = 1.1,xend = 1.1,
  y = c(32,31,30,29,28,27,26,25,24,23,22,21,23,22,28,22,23,21,22),
  yend=c(19,18,17,16,15,14,13,12,11,10,9,8,7,6,5,4,3,2,1))

p2 <- data.frame(id=c(1:19,21:32),
           type=c(rep("Target",19),rep("Source",12)),
           x="type") %>% 
  ggplot(.,aes(x=x,y=id)) +
  geom_point(pch=21,size=4,aes(fill=type)) +
  # 添加曲线设置不同弯曲度
  geom_curve(data=df_curve %>% slice(1:6),aes(x=x,xend=xend,y=y,yend=yend),
             inherit.aes = F,
             curvature = -0.5,color="grey60", # 正值：向左弯；负值：向右弯
             arrow = arrow(length = unit(0.06, "inches"),type = "closed")) +
  geom_curve(data=df_curve %>% slice(7:n()),aes(x=x,xend=xend,y=y,yend=yend),
             inherit.aes = F,
             curvature = -0.3,color="grey60",    
             arrow = arrow(length = unit(0.06, "inches"),type = "closed")) +
  # 添加垂直线段
  geom_curve(data=df_curve,aes(x=3,xend=3,y=28,yend=4),inherit.aes = F,
             curvature = 0,color="#7da7ea", 
             arrow = arrow(length = unit(0.1, "inches"),type = "closed")) +
  annotate(geom="text",x=3,y=28.5,label="Source",size=4)+ 
  annotate(geom="text",x=3,y=3.5,label="Target",size=4)+ 
  scale_y_continuous(expand= expansion(mult = c(0.02,0.02)))+
  scale_fill_manual(values = c("#E6A0C4","#74A089")) +
  coord_cartesian(clip='off') +
  theme_void() +
  theme(legend.position ="none",
        plot.margin = margin(0,1,0,0,unit="cm"))
# 注释条带
p3 <- dff %>% filter(Gene=="Tissues") %>% 
  dplyr::rename("Cell type"="value") %>% 
  ggplot(aes(name,Gene,fill=`Cell type`)) +
  geom_tile() +
  scale_fill_manual(values = c("#E6A0C4","#66C2D7","#7da7ea","#74A089")) +
  theme_void() +
  theme(legend.background = element_blank(),
        legend.position = "left",
        plot.margin = margin(0,0,0,0,unit="cm"))
# 拼图
# 通过plot_spacer()添加空白的方式来微调对齐
pp <- (p1/p3) +plot_layout(heights =c(1,0.05)) +
  plot_layout(guides = 'collect')& theme(legend.position = 'left')

pp2 <- (p2/plot_spacer()) + plot_layout(heights =c(1,0.04))
  
(pp|pp2) + plot_layout(widths = c(3,1))