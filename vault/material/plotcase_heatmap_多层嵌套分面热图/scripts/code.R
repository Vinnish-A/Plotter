library(tidyverse)
library(readxl)
library(ggh4x)
library(legendry)

sessionInfo()

# 筛选左侧热图数据
df1 <- read_excel("41591_2025_3891_MOESM6_ESM.xlsx",sheet = 1) %>% 
  filter(wins_hr !="NA") %>% 
  mutate(wins_hr=as.numeric(wins_hr))

# 此段代码主要点在于guides与facet_nested这两部分，读者需要留意些应用范围很广泛
p1 <- ggplot(df1, aes(
  x=anno_model, y=interaction(anno_metabolite_name_sig,super_class_metabolon))) +
  geom_tile(aes(fill=wins_hr)) +
  scale_fill_gradient2(low="#466983",mid="white",high="#8b0000",midpoint = 1,
                       guide = "colourbar",na.value="gray") +
  scale_x_discrete(position = "bottom",expand = c(0,0)) +
  scale_y_discrete(expand = c(0,0)) +
 geom_text(aes(label=sig), color="black", size=6, nudge_y = -0.3) +
  labs(fill="Hazard ratio", size=12,x=NULL,y=NULL) +
  coord_cartesian(clip="off") +
  # 绘制左侧的注释条带
  guides(y = legendry::guide_axis_nested(
    type = "box",
    key = key_range_auto(sep = "\\."),
    drop_zero = FALSE, # 若一组只有一个数据则要定义为F
    pad_discrete = 0.5, #设置0.5条带之间无间距
    min_size=0.5, # 设置条带宽度
    levels_text = list(
      # y轴文本
      element_text(size=8,vjust=0.5,color="black"),
      element_text(size=0)), # 注释条带的分组文本，在此不显示
    # 条带的填充色及边框颜色
      levels_box=list(
        element_rect(
          fill=c("#5A77D190","#EC7A05","#466983",
                 "#82B7F590"),color="NA"))))+
  theme_test() +
  theme(axis.text.y=element_text(color="black",size=8),
        axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1, size = 10, colour = "black"),
        axis.ticks.y=element_blank(),
        panel.spacing.x = unit(0.5,"line"),
        legend.position = "bottom",
        legend.title = element_text(size=11),
        legend.title.position = "top",
        legend.text = element_text(size=10),
        legend.key.width = unit(1,"cm")) +
  # X轴嵌套分面
  facet_nested(~ analysis_group + gene_group_anno,
               labeller = label_parsed, drop = T, scales="free_x", space="free_x",
               # 定义填充背景及边框属性
               strip = strip_nested(
                 background_x = elem_list_rect(
                   color=c("black","black","black"),
                   fill = c("#466983","white","white"),linewidth=rep(0.5,3)),
                 text_x = elem_list_text(color=c("white","black","black"),
                                         size=rep(10,3),face="bold")))
# 筛选右侧热图数据
df2 <- read_excel("41591_2025_3891_MOESM6_ESM.xlsx",sheet = 2)

p2 <- ggplot() +
  geom_tile(data=df2,aes(inter_term,anno_metabolite_name_sig,
                         fill=wins_beta_fdr)) +
  scale_fill_gradient2(low="#84ad2d",mid="white",high="#e88f1a",
                       midpoint = 0,guide = "colourbar",
                       breaks = c(-0.05,0,0.05),na.value="gray") +
  scale_x_discrete(position = "bottom",expand = c(0,0),
                   labels=ggplot2:::parse_safe) +
  scale_y_discrete(expand = c(0,0)) +
  geom_text(data=df2,aes(inter_term,anno_metabolite_name_sig,
                         label=sig), color="black",
            size=6, nudge_y = -0.3) +
  labs(fill=expression(beta * " \u00D7 -log"[10]*"(FDR)"), size=12,
       x=NULL,y=NULL) +
  theme_test() +
  theme(axis.text.x = element_text(
    angle = 45, vjust = 1,hjust = 1, size = 10, colour = "black"),
        axis.text.y=element_blank(),
        axis.ticks.y=element_blank(),
        panel.spacing.x = unit(0.5,"line"),
        legend.position = "bottom",
        legend.title = element_text(size=11),
        legend.title.position = "top",
        legend.text = element_text(size=10),
        legend.key.width = unit(1,"cm")) +
  facet_nested(~ analysis_group + gene_group_anno,
               labeller = label_parsed, drop = T,
               scales="free_x", space="free_x",
               strip = strip_nested(
                 background_x = elem_list_rect(
                   color=c("black","black","black"),
                   fill = c("darkgreen","white","white"),
                   linewidth=rep(0.5,3)),
                 text_x = elem_list_text(
                   color=c("white","black","black"),
                   size=rep(10,3),face="bold")))

library(patchwork)

(p1|p2)+plot_layout(widths = c(1,1.2))