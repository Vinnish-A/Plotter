library(tidyverse)
library(legendry)

sessionInfo()

df <- read_tsv("prevlance.stat5.tsv")

ggplot(df,aes(HH_type, interaction(category,group),
              size = rate,fill = percent)) +
  # 设置边框
  geom_tile(col = "black",fill = "white",linewidth = 0.3,show.legend = F) +
  # 筛选部分数据进行灰色背景填充
  geom_tile(data= df %>%
              filter(HH_type %in% c("Within","Between"),
                     category %in% c("Human - Human","Poultry - Poultry")),
            fill="grey80",color="black",linewidth = 0.3,
            show.legend = F)+
  # 添加数据
  geom_point(shape = 21, colour = "black") +
  # 添加文本
  geom_text(data=df %>% filter(text !="(0/0)"),
            aes(label = text), col = "black",
            size =8,  nudge_y = -0.3,size.unit = "pt") +
  # 分面
  facet_grid(. ~ subcounty, scales = "free_x", space = "free_x") +
  scale_size(range = c(1.5,7),
    name = "Strain-sharing rate") +
  # 自定义颜色
  scale_fill_gradient2(low = "#ffffcc", mid= "#41b6c4",high = "#253494",
                       midpoint = 25,
                       limits = c(0,50),breaks = c(0,10,20,30,40,50),
                       name = "Prevalence (%)",
                       labels = c(0,10,20,30,40,50)) +
  # 设置Y轴文本分组
  guides(
    y = legendry::guide_axis_nested(
      key = legendry::key_range_auto(sep="\\."),
      drop_zero = FALSE, # 若某些组内只有一个则需要设置此参数为F
      levels_text = list(
        element_text(size=9), # 内层Y轴文本
        # 分组文本
        element_text(face="bold",angle = 0)))) +
  labs(x=NULL,y=NULL) +
  coord_cartesian(clip="off") +
  theme(
    panel.background = element_blank(),
    plot.background = element_blank(),
    panel.spacing.x = unit(-0.1,"cm"),
    strip.background = element_blank(),
    strip.text = element_text(face="bold"),
    axis.text.x = element_text(angle=45,hjust=1),
    axis.ticks = element_blank(),
    legend.position = "right",
    plot.margin = margin(0.3,0.5,0.3,0.5,"cm"))

