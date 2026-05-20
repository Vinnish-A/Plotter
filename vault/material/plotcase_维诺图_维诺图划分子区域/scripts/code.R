library(tidyverse)
library(devtools)
#install_github("AllanCameron/VoronoiPlus")
library(VoronoiPlus)

source("voronoi_style.R")

df <- read_tsv("data.tsv", show_col_types = FALSE)

long <- pivot_longer(df,cols = -Individual,names_to = "Phylum",
                     values_to = "value")

ggplot() +
  geom_voronoi_nested(data = long,  # 输入长表数据
                      top_col = "Phylum",  # 一级分组列（大区域）
                      sub_col = "Individual",  # 二级分组列（区域内小块）
                      value_col = "value",  # 权重列，决定面积大
                      legend_title = "Phyla",  # 图例标题
                      speed = "fast",  # 使用快速模式
                      palette = c(Actinobacteria = "#1f77b4",Bacteroidetes = "#d62728", 
                                  Cyanobacteria = "#f1e15b",Euryarchaeota = "#b58900", 
                                  Firmicutes = "#2aa198",Fusobacteria = "#2ca02c",  
                                  Proteobacteria = "#bf00ff",Spirochaetes = "#1e00ff",  
                                  Synergistetes = "#6a0dad",Tenericutes = "#ff1493", 
                                  Verrucomicrobia = "#228b22"), 
                      sub_border = "grey60",sub_linewidth = 0.5,  # 小块分割线颜色与粗细
                      top_border = "grey70",top_linewidth = 0.8,  # 一级大区边界颜色与粗细
                      outer_border = NA, outer_linewidth = 0) +  # 关闭最外层圆形边框
  guides(fill = guide_legend(override.aes = list(colour = NA))) +
  coord_equal() +  
  theme_void() +  
  theme(legend.key.spacing.y = unit(0.1,"cm"),
        legend.key.height = unit(0.4,"cm"),
        legend.key.width = unit(0.4,"cm"),
        legend.background = element_blank(),  
        legend.key = element_blank(), 
        legend.text = element_text(color="black",size=10))

