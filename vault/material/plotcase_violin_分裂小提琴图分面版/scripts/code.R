library(tidyverse)
library(vroom)
# devtools::install_github("psyteachr/introdataviz")
library(introdataviz)
library(ggpubr)
library(ggpp)

sessionInfo()

df <- read_tsv("violin_data.tsv")

#在分面绘图中添加分组A,B,C标记主要通过ggpp::geom_text_npc( )函数实现，因此需要先定义一个文本数据

df$type <- factor(df$type,levels = rev(unique(df$type)))
label <- tibble(label = LETTERS[1:6],x = "left", y = "top",
                name = c("SOC (g kg-1)","DOC(mg kg-1)",
                         "Soil temperate","Soil moisture (%)",
                         "Aboveground biomass (Mg ha-1)","Root biomass")) %>% 
  mutate(label = paste0("(", label, ")"))

label$name <- factor(label$name,levels = label$name)

ggplot(df, aes(x = type,y=value,fill = group)) +
  # 绘制分裂小提琴图，不添加轮廓线 color=NA，
#  调整小提琴图的平滑度 adjust = 1
  geom_split_violin(trim = F,color = NA, adjust =1) +
  stat_summary(fun.data="mean_sd",position=position_dodge(0.15),
               geom="errorbar", width = .1)+
  stat_summary(fun="mean",geom="point",
               position=position_dodge(0.15),
               show.legend = F) +
  scale_fill_manual(values = c("#C6CDF7", "#E6A0C4")) +
  ggpp::geom_text_npc(data = label,
                      aes(npcx = x, npcy = y, label = label)) +
  stat_compare_means(aes(group = group),
                     method="wilcox.test",label="p.signif",vjust=-1) + 
  facet_wrap(.~name,scale="free_y",strip.position ="left",nrow=2)+
  labs(x=NULL,y=NULL) +
  guides(fill=guide_legend(position = "inside")) +
  theme_test() +
  theme(strip.placement = "outside",
        strip.background = element_blank(),
        strip.text=element_text(color="black",size=11),
        axis.text.x=element_text(color="black"),
        axis.text.y=element_text(color="black"),
        legend.title = element_blank(),
        legend.key.height = unit(0.4,"cm"),
        legend.key.width = unit(0.4,"cm"),
        legend.background = element_blank(),
        legend.position.inside = c(0.25,0.55))