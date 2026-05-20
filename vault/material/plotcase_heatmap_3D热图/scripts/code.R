BiocManager::install("ComplexHeatmap")
library(tidyverse)
library(ComplexHeatmap) # Version:2.24.0
library(corrplot)

sessionInfo()

mat <- read_tsv("data3.tsv") %>% 
  select(Relative.abundance ,dataset,Phylum) %>% 
  pivot_wider(names_from = "Phylum",values_from = "Relative.abundance") %>% 
  column_to_rownames(var="dataset") %>% 
  as.matrix()

col_fun <- COL2('PRGn') # 定义颜色

ht_opt$HEATMAP_LEGEND_PADDING = unit(0.5,"cm") # 设置热图全局参数
ht_opt$TITLE_PADDING = unit(c(0.2,0.2),"cm")

# 使用 ComplexHeatmap 包创建 3D 热图
Heatmap3D(mat, name = "mat", column_title = " ", 
          row_names_gp = gpar(fontsize =10), # 设置行名的字体大小
          column_names_gp = gpar(fontsize =10), # 设置列名的字体大小
          column_title_gp = gpar(fontsize = 11),
          row_order = NULL,col = col_fun)

