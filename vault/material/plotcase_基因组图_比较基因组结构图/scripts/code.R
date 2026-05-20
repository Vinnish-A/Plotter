install.packages("tidyheatmaps")
library(tidyheatmaps)
library(tidyverse)

sessionInfo()

ann_colors <- list(
  condition = c(EAE = "#BD79B4", healthy = "#F5CEF2"),
  group = c(Ein = "#C14236", Eip = "#E28946", Hin = "#4978AB", Hip = "#98BB85"),
  sample_type = c(input = "#BDBDBD", IP = "#7D7D7D"),
  direction = c(down = "#5071DC", up = "#C34B6B"),
  is_immune_gene = c(yes = "#B69340", no = "#F5CEF2"))

tidyheatmap(data_exprs,
            rows = external_gene_name,
            columns = sample,
            values = expression,
            scale = "row",
            annotation_col = c(sample_type, condition, group),
            annotation_row = c(is_immune_gene, direction),
            annotation_colors = ann_colors,
            gaps_row = direction,
            gaps_col = group,
            # cellwidth = 10,
            # cellheight = 10,
            cluster_rows = TRUE, # 行聚类
            cluster_cols = TRUE, # 列聚类
            #  display_numbers = TRUE, # 是否显示数值
            # 定义需要显示的基因
           # show_selected_row_labels = c("Apol6","Bsn","Vgf","Fam96b","Bag1","Aip")
)
