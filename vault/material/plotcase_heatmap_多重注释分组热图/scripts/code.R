library(tidyverse)
library(readxl)
library(grid)
library(jjAnno)
library(MetBrewer)

sessionInfo()

df <- read_excel("data.xlsx") %>% pivot_longer(-c(ID,group))

df$ID <- factor(df$ID,levels = df$ID %>% unique() %>% rev())
df$group <- factor(df$group,levels = df$group %>% unique() %>% rev())

# 绘制主图
p1 <- df %>% 
  ggplot(aes(name,ID))+
  geom_tile(color="black",fill="white",size=0.3)+
  geom_point(data=df %>% filter(value > 0.08),
             aes(size=abs(value),color=value),shape=15,size=7)+
  scale_color_gradientn(colors=met.brewer("Cassatt1"))+
  coord_cartesian(clip = "off")+
  scale_y_discrete(expand=c(0,0),position = 'left')+
  scale_x_discrete(expand=c(0,0),position = 'top')+
  labs(x=NULL,y=NULL) +
  theme(plot.margin = margin(1,1,1,10,unit = "cm"),
        panel.background = element_blank(),
        axis.text.x = element_text(color="black",size=8),
        axis.text.y=element_text(color="black"),
        legend.title = element_blank(),
        axis.ticks = element_blank()) +
  guides(color=guide_colorbar(direction = "vertical",
                              reverse=F,barwidth=unit(.5,"cm"),
                              barheight=unit(21,"cm")))+
  annotation_custom( # 添加垂直线段
    grob=grid.segments(gp=gpar(col="black",fill="black",lwd=1)),
    xmin=-9,xmax=-9,ymin=0.5,ymax =32.5)


add_extension_lines <- function(plot, data) {
  n_rows <- length(unique(data$ID))
  n_cols <- length(unique(data$name))
  
  # 添加水平延长线条
  for (i in seq_len(n_rows + 1)) {
    plot <- plot + annotation_custom(
      grob = linesGrob(gp = gpar(lwd=1)), 
      xmin =-9, xmax = n_cols+0.5, ymin = i - 0.5, ymax = i - 0.5
    )
  }
  
  return(plot)
}
# 对Y轴添加水平延伸线
p2 <- add_extension_lines(p1,df)

# 定义函数用于添加分组延长线
add_custom_lines <- function(plot, positions, xmin, xmax, color = "black", lwd = 1) {
  for (pos in positions) {
    plot <- plot + annotation_custom(
      grob = linesGrob(gp = gpar(col = color, fill = color, lwd = lwd)),
      xmin = xmin, xmax = xmax, ymin = pos, ymax = pos
    )
  }
  return(plot)
}
# 定义分组延长线位点
positions <- c(0.5, 3.5, 4.5,5.5,6.5,15.5,20.5,21.5,27.5,31.5,32.5)
# 添加延长线
p3 <- add_custom_lines(p2, positions, xmin = -9, xmax = -18.8,
                       color = "black", lwd = 1)+
  annotation_custom( # 线条添加箭头
    grob=grid.segments(gp=gpar(col="black",fill="black",lwd=1)),
    xmin=-18.8,xmax=-18.8,ymin=0.5,ymax =32.5)
# 添加分组文本
plot <- annoRect(object = p3,annoPos = "left",aesGroup = T,
         aesGroName = "group",
         alpha = 0.5,
         textCol = c(rep("black",10)),
         xPosition = c(-9,0.5),
         addText = T,textSize = 10,
         textHVjust = -14.5,hjust=0,vjust=0.5)

ggsave(plot.file="plot.pdf",width=10.53,height=9.75,unit="in")

