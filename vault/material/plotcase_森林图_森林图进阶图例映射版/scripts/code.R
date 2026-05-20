library(tidyverse)
library(ggh4x) 
library(ComplexHeatmap)
library(grid)
library(RColorBrewer)

sessionInfo()

df <- read_tsv("data.tsv")
df$Variable <- factor(df$Variable,levels = rev(df$Variable))
# 构建图例颜色映射
mycolor <- df %>% drop_na() %>% select(Cell_Type) %>% 
  mutate(col=brewer.pal(10,"Paired")) %>% deframe()

# 此段森林图的绘制代码看起来较长，实则为几个图层重复使用，并且添加了图形外部的分组注释。

df %>% ggplot(aes(y=Variable)) +
  # 添加背景条带，偶数行添加
  geom_rect(data=df %>% filter(id %% 2 == 0),inherit.aes = F,
            aes(ymin=id-0.5,ymax=id+0.5),xmin=-0.7,xmax=Inf,
            fill="grey90")+
  # 添加图中的方块点
  geom_point(aes(x=HR,y=Variable),shape=15,size=3) +
  # 天津置信区间数据
  geom_errorbarh(aes(xmin=CI_lower,xmax=CI_upper),height=0.2) +
  labs(x=NULL,y=NULL)+ 
  coord_cartesian(clip = "off") + # 关闭图形裁剪
  # 定义X轴属性，只显示0.5-2.5的刻度条
  scale_x_continuous(limits = c(-0.7,2.8),
                     breaks = c(0.5,1,1.5,2,2.5),
                     labels = c(0.5,1,1.5,2,2.5),
                     guide=guide_axis(cap = TRUE)) +
  # 添加文本
  geom_text(data=df,
            aes(x =0,y=Variable,label=`HR (95% CI)`),
            size=4,fontface = "bold")+
  # 添加序号，由于是从第5行开始，因此先筛选数据
  geom_point(data=df %>% slice(5:n()),
             aes(x=-0.5,Variable,fill=Cell_Type,color=Cell_Type),
             size=8,pch=21,show.legend = F) +
  # 自定义颜色
  scale_fill_manual(values = mycolor) +
  scale_color_manual(values = mycolor) +
  geom_text(data=df %>% slice(5:n()),
            fontface = "bold",
            aes(x =-0.5,y=Variable,label=Variable),
            size=4,color="white") +
  geom_text(data=df %>% slice(1:4),
            fontface = "bold",hjust=0,
            aes(x =-0.6,y=Variable,label=Variable),
            size=4,color="black") +
  geom_text(aes(x =2.5,y=Variable,label=P_value),
            size=4,fontface = "italic",hjust=0) +
  geom_text(aes(x =0,y=max(id)+1),size=4,
            label="HR (95% CI)",fontface = "bold") +
  geom_text(aes(x =-0.5,y=max(id)+1),size=4,
            label="Variable",fontface="bold") +
  geom_text(aes(x =2.65,y=max(id)+1),size=4,
            label="P_value",fontface = "bold")+
  # 添加垂直线
  annotate(geom="segment",x=1,xend=1,
           y=0.5,yend=13.5,color="black",linetype=2) +
  theme(axis.text.y=element_blank(),
        axis.text.x=element_text(color="black",face="bold",size=11),
        axis.ticks.y=element_blank(),
        panel.background = element_blank(),
        axis.line.x=element_line(color="black"),
        plot.margin = margin(0.5,6,0.5,0.5,unit="cm"))+
  coord_cartesian(clip="off") +
  # 添加左侧分组条带线
  annotation_custom( 
    grob=grid.segments(gp=gpar(col="black",fill="black",lwd=1.5)),
    xmin=-0.75,xmax=-0.75,ymin=8.6,ymax =10.5) +
  annotation_custom( 
    grob=grid.segments(gp=gpar(col="black",fill="black",lwd=1.5)),
    xmin=-0.75,xmax=-0.75,ymin=3.5,ymax =8.3) +
  annotation_custom( 
    grob=grid.segments(gp=gpar(col="black",fill="black",lwd=1.5)),
    xmin=-0.75,xmax=-0.75,ymin=0.5,ymax =3.3) +
    # 添加左侧分组文本
  annotation_custom(
    grob = grid.text(label="Mono",hjust=0,vjust=0,rot=90,
                     gp=gpar(col="black",fontsize=12,
                             fontface="bold")),
    xmin=-0.76,xmax=-0.76,ymin=8.5,ymax=9.5) +
  annotation_custom(
    grob = grid.text(label="TAM",hjust=0,vjust=0,rot=90,
                     gp=gpar(col="black",fontsize=12,
                             fontface="bold")),
    xmin=-0.76,xmax=-0.76,ymin=5,ymax=6)+
  annotation_custom(
    grob = grid.text(label="DC",hjust=0,vjust=0,rot=90,
                     gp=gpar(col="black",fontsize=12,
                             fontface="bold")),
    xmin=-0.76,xmax=-0.76,ymin=1.5,ymax=1.75)

# 自定义绘制图例
# 该段代码主要使用ComplexHeatmap包内的Legend函数来自定义绘制图例，
# 看起来较为复杂实则为通用型，主要点在于生成图例并在图例色块中添加数字编号。
  
col_values <- mycolor
label_id <- c(1,2,3,4,5,6,7,9,10,11)

graphics_list <- lapply(seq_along(col_values), function(i) {
  function(x, y, w, h) {
    # 圆点
    grid.points(x, y, pch = 21, size = unit(7, "mm"),
                gp = gpar(col =col_values[i],fill = col_values[i]))
    # 圆内编号（手动编号而非默认i）
    grid.text(label = as.character(label_id[i]), x = x, y = y,
              gp = gpar(col = "white", fontsize = 9, fontface = "bold"))
  }
})

lgd <- Legend(labels = names(col_values), 
              # 使用 graphics_list 中的绘图函数
              graphics = graphics_list, 
              column_gap = unit(15,"mm"),
              row_gap = unit(5, "mm"),
              labels_gp = gpar(col = "black",fontsize =9))

draw(lgd, x = unit(0.88, "npc"),
     y = unit(0.15, "npc"), just = c("bottom"))