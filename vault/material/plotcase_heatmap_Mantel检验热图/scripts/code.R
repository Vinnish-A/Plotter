library(tidyverse)
library(vegan)
library(psych)
# install.packages("devtools")
# devtools::install_github("Hy4m/linkET", force = TRUE)
library(linkET)
library(corrplot)
library(magrittr)
library(reshape)
library(ggtext)

sessionInfo()
# 加载vegan内部数据
data("varechem")
data("varespec")
# mantel_test分析
mantel <- mantel_test(varespec, varechem,
                      spec_select = list(
                        Spec01 = 1:7,Spec02 = 8:18,Spec03 = 19:20)) %>% 
  mutate(rd = cut(r, breaks = c(-Inf, 0.2, 0.4, Inf),
                  labels = c("< 0.2", "0.2 - 0.4", "&ge; 0.4")),
         pd = cut(p, breaks = c(-Inf, 0.01, 0.05, Inf),
                  labels = c("< 0.01", "0.01 - 0.05", "&ge; 0.05")))
# 绘图
qcorrplot(correlate(varechem,method = "pearson"),
          diag=F,type="lower",grid_col = "grey30")+
  geom_tile() +
  geom_mark(size=2.5,sep="\n")+ # 添加显著性标记
  # 定义填充颜色
  scale_fill_gradientn(colors=rev(COL2('PRGn',100)),na.value = "white")+
  # 添加右侧连接线，此处使用mantel分析的结果
  geom_couple(aes(colour=pd,size=rd),data=mantel,
              label.colour = "black", curvature=nice_curvature(),
              label.fontface=0,
              label.size =3.5,drop = T,
              node.colour = c("white", "white"),
              node.fill = c("#984EA3","#5785C1"),
              node.size = c(4.5,4),
              node.shape=c(23,21))+
  coord_cartesian(clip="off")+
  # 定义线条大小
  scale_size_manual(values = c(0.5,1,2))+
  # 定义线条颜色
  scale_colour_manual(values = c("#984EA3", "#4DAF4A", "grey"))+
  # 定义图例属性
  guides(fill = guide_colorbar(title = "pearson's r",order = 1),
         color = guide_legend(
           title = "mantel's p",order = 2,
           theme = theme(
             legend.title = element_text(color="black"),
             legend.text = element_markdown(color="black"))),
         size = guide_legend(
           title = "mantel's r",order = 3,
           theme = theme(
             legend.title = element_text(color="black"),
             legend.text = element_markdown(color="black"))))+
  theme(plot.margin = unit(c(0.5,0,0.5,0.5),units="cm"),
        axis.text.x=element_text(size=9,color=c(rep("black",13),"white")),
        axis.ticks =element_blank(),
        panel.background = element_blank(), 
        legend.key = element_blank(), 
        legend.background = element_blank())

