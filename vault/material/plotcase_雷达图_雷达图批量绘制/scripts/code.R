library(tidyverse)
# devtools::install_github("ricardo-bion/ggradar",dependencies = TRUE)
library(ggradar) # Version: 0.2
# install.packages("scales")
library(scales)
library(patchwork)

df <- read_tsv("data.tsv")

facettest <- df %>% select(-id) %>% 
# 定义分组
  mutate(group=c("food prophageARGs","animal.husbandry prophageARGs",
                 "human prophageARGs","soil prophageARGs","Sediment prophageARGs",
                 "Wild.animal prophageARGs","Surface.water prophageARGs",
                 "Aquatic.organism prophageARGs",
                 "Insects prophageARGs","Seawater prophageARGs",
                 "Plant prophageARGs")) %>% 
  relocate(group)
# 定义颜色
color_palette <- c("food prophageARGs"="#78A8C6",
                   "animal.husbandry prophageARGs"="#BEBADA",
                   "human prophageARGs"="#8DD3C7",
                   "soil prophageARGs"="#F37D74",
                   "Sediment prophageARGs"="#BEE0BE",
                   "Wild.animal prophageARGs"="#F5C2D9",
                   "Surface.water prophageARGs"="#A0CE3A",
                   "Aquatic.organism prophageARGs"="#9D9E98",
                   "Insects"="#AA7CB6",
                   "Seawater prophageARGs"="#F2E27B",
                   "Plant prophageARGs"="#FCB461")

plots <- lapply(unique(facettest$group), function(g) {
  data_subset <- facettest %>% filter(group == g)  # 筛选对应组的数据
  
  ggradar(data_subset,
          group.line.width = 1,  # 线宽
          group.point.size = 2,  # 数据点大小
          grid.label.size = 3,  # 网格标签字体大小
          axis.label.size = 3,  # 轴标签字体大小
          axis.line.colour = "grey",  # 轴线颜色
          background.circle.colour = "white",  # 背景颜色
          legend.text.size = 10,  # 图例字体大小
          gridline.min.linetype = "longdash",  # 最小网格线
          gridline.mid.linetype = "longdash",  # 中间网格线
          gridline.max.linetype = "longdash",  # 最大网格线
          gridline.min.colour = "grey",
          gridline.mid.colour = "#007A87",
          gridline.max.colour = "black") +
    ggtitle(g) + # 每张图的标题为 group 名称
    coord_cartesian(clip="off") +
    scale_color_manual(values = color_palette[g]) +
    theme(plot.title = element_text(size = 10,vjust=0.5,hjust=0.5,
                                    face="bold",color="black"))
})

# 使用 patchwork 拼接多个雷达图
final_plot <- wrap_plots(plots, ncol = 4)  # 设定每行 4个图
print(final_plot)