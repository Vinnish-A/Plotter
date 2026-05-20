library(tidyverse)
library(legendry)
library(ggtext)
install.packages("ggplot2")
library(ggplot2)
library(PieGlyph)

sessionInfo()

# 数据构建
# 由于此图的Y轴文本含有重复，因此先用行号替代后续在通过scale_y_discrete替换labels
genes <- c("Trp63","Krt5","Krt15","Krt17",
  "Ascl1","Syp","Chga","Insm1","Chgb","Myt1","Sez6",
  "Foxa2","Mycl","Neurod1","Nhlh2","Neurod2",
  "Atoh1","Ush2a","Lhx3","Rasd2","Pou4f3","Pou2f3",
  "Trpm5","Ascl2","Lrmp","Gng13","Avil",
  "Alox5","Atp2a3","Cftr",
  "Ascl3","Stap1","Pparg","Yap1","Wwtr1","Sox2","Cd44","Hes1","Vim",
  "Top2a","Mki67","Ube2c","Aspm","Myc","fLuc")

groups <- c(paste0("RPM_", 1:13), paste0("RPMA_", 1:8))

df <- expand.grid(Gene = genes, Group = as.character(groups),
                  stringsAsFactors = FALSE) %>% as_tibble() %>%
  mutate(mean_expr = runif(n(), min = 0, max = 5),   # 模拟平均表达
    frac_pct  = runif(n(), min = 0, max = 100))  # 模拟细胞比例
# 分组文件读取
dff <- df %>% left_join(.,read_tsv("heat.tsv"),by="Gene")
dff$Group.x <- factor(dff$Group.x,levels = unique(dff$Group.x))
dff$Group.y <- factor(dff$Group.y,levels = rev(unique(dff$Group.y)))

# 该图主要就是绘制左侧的分组线及文本信息，此前该功能多由ggh4x包实现，但目前作者将其迁移到了legendry包中，
# 并做了些许修改，因此会有一些用法上的不同，具体看代码guides()内的内容。

p1 <- dff %>% ggplot(aes(Group.x,interaction(Gene,Group.y),
                   size=frac_pct,color=mean_expr)) +
  annotate("rect", xmin = 0.5, xmax = 13.5, ymin = -Inf, ymax = Inf,
           fill = "#E8DAEF", alpha = 0.4) +   # 淡紫色
  annotate("rect", xmin = 13.5, xmax = 20.5, ymin = -Inf, ymax = Inf,
           fill = "#FCF3CF", alpha = 0.4) +
  geom_point(stroke = 0) +
  guides(y = legendry::guide_axis_nested(key = key_range_auto(sep = "\\."),
                               levels_text = list(
                                 element_text(angle = 0),   # 内层基因名
                                 element_text(angle = 90,face = "bold",vjust=0.5,hjust=0.5)) 
                               )) +
  scale_color_gradientn(
    colors = c("#D8F0F8","#91BFDB", "#756BB1","#542788" ),
    breaks = c(min(df$mean_expr), max(df$mean_expr)),
    labels = c("Min", "Max"),
    name="Mean expression<br> in group")+
  scale_x_discrete(label=c("8","7","18","9","4","20","11",
                           "14","1","19","0","6",
                           "17","15","3","2","13","12",
                           "10","5","16"),position = "top") +
  scale_size_continuous(limits = c(20,100),
                        breaks = c(20,40,60,80,100),
                        labels = c("20","40","60","80","100"),
                        name="Fraction of cells <br> in group (%)") +
  labs(x=NULL,y=NULL) +
  coord_cartesian(clip="off") +
  theme_test() +
  theme(axis.text.y  = element_text(
    hjust=1,vjust=0.5,color="black",face = "bold.italic"),
    axis.text.x.top=element_text(color="black",face="bold",
                                 angle = 90,vjust=0.5,hjust = 0),
    legend.title.position = "top",
    legend.title = element_markdown(vjust=0.5,hjust=0.5),
    legend.background = element_blank(),
    legend.position = "bottom",
    legend.frame = element_rect(color="black"),
    axis.ticks = element_blank(),
    legend.text.position = "bottom",
    plot.margin = margin(0,0.5,0,0.5,unit="cm"))

# 根据热图构建数据，后两列数值就是饼图占比
pie <- data.frame(x=c("8","7","18","9","4","20","11",
                      "14","1","19","0","6",
                      "17","15","3","2","13","12",
                      "10","5","16"),y="type",
                  RPM=c(1,1,1,1,0.8,1,1,1,1,1,1,1,
                        0.9,0.3,0,0,0,0.2,0.1,0.2,0.6),
                  RPMA=c(0,0,0,0,0.2,0,0,0,0,0,0,0,
                         0.1,0.7,1,1,1,0.8,0.9,0.8,0.4)) %>% 
  mutate(group=c(rep("RPM",13),rep("RPMA",8))) %>% 
  as_tibble()
# 定义因子保证顺序一致
pie$x <- factor(pie$x,levels =pie$x)

# 绘图
p2 <- ggplot(data = pie,aes(x = interaction(x,group),y = y))+
  # 绘制饼图
  geom_pie_glyph(slices=3:4,colour = NA,radius=0.2) +
  scale_x_discrete(position = "top") +
  scale_y_discrete(expand = c(0,0)) +
  scale_fill_manual(values = c(
    "RPM"  = "#984EA3","RPMA" = "#E6550D"))+
  # 添加x轴分组文本信息
  guides(x = legendry::guide_axis_nested(
    key = key_range_auto(sep = "\\."),
    levels_text = list(
      element_text(angle = 90,size=0),  
      element_text(angle = 0,face = "bold",
                   size=13,color=c("#984EA3","#E6550D"))))) +
  labs(title = "Enriched in") +
  theme(legend.position = "none",
        axis.ticks = element_blank(),
        axis.title = element_blank(),
        axis.text.y=element_blank(),
        panel.background = element_blank(),
        plot.title = element_text(
          color="black",size=14,vjust=0.5,hjust=0.5))
# 拼图
library(patchwork)

(p2/p1)+plot_layout(heights = c(0.05,1))

