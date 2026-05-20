library(ComplexHeatmap) 
library(circlize)
library(tidyverse)

mat <- read_tsv("data.tsv")
mat$gene_name <- make.unique(mat$gene_name)

ht <- mat %>% column_to_rownames("gene_name") %>% as.matrix()

# 定义需要高亮显示的基因名列表
si.hilight <- c(
  "Myc","Sox4","Tet3","Mynn","Egr3","Zeb1","Gata2",
  "Hoxb4","Nr6a1","Nfia","Pou2f2",
  "Yy1","Arntl","Smad3","Rfx3","Hes1",
  "Sox7","Cux1","Pou5f1","Dmr5a1","Nfkb1","Bach1","Ppard",
  "Foxb1","Foxf2","Tbx6","Rorb","Cphx2",
  "Nr4a3","Jun","Nr4a1","Junb","Klf4","Klf6","Fos","Snai1",
  "Nr3c2","Irf7","Nfkb2","Cebpd","Six5","Stat5b","Irf5",
  "Sox8","Zfp184","Mxi1","Ovol2","Rfx4",
  "Zscan20","Zfp143","Zbtb49","Zbtb3","Thrb")

# 创建行注释，用于标记需要高亮的基因
hi <- rowAnnotation(
  foo = anno_mark(at = match(si.hilight,rownames(ht)), # 高亮基因在矩阵中的位置
                  labels = rownames(ht)[match(si.hilight, rownames(ht))], # 对应基因标签
                  labels_gp = gpar(fontsize=10)))
# 定义热图的颜色映射
heat.color <- circlize::colorRamp2(
  c(-2, 0, 2),c("#69AADB","white","#D45590"))

state_clean <- colnames(ht) %>%
  stringr::str_extract("^[^_]+") %>%
  { case_when(
    . == "Naive"                 ~ "Naive",
    . == "MP"                    ~ "MP",
    . == "TE"                    ~ "TE",
    . == "TCM"                   ~ "TCM",
    . == "TEM"                   ~ "TEM",
    stringr::str_starts(., "TRM")     ~ "TRM",
    stringr::str_starts(., "TexProg") ~ "TEXprog",
    stringr::str_starts(., "TexEff")  ~ "TEXeff",
    stringr::str_starts(., "TexTerm") ~ "TEXterm",
    TRUE ~ NA_character_)
  } %>%
  factor(levels = c(
    "Naive","MP","TE","TCM","TEM",
    "TRM","TEXprog","TEXeff","TEXterm"))

state_col <- c("Naive"= "#D9D9D9","MP" = "#F4A3C2","TE" = "#5B8FF9",
  "TCM" = "#F6C85F","TEM" = "#6DC8EC","TRM" = "#4CAF50",
  "TEXprog" = "#F7B7B7","TEXeff" = "#7FB3D5","TEXterm" = "#8D6E63")


ha_top <- HeatmapAnnotation(
  State = state_clean,
  col = list(State = state_col),
  show_annotation_name = FALSE,
  annotation_height = unit(3, "mm"))

Heatmap(ht,
  cluster_rows = TRUE,        # 行做聚类
  row_km = 6,                 # 按聚类结果拆成 6 个模块
  show_row_dend = FALSE,      # 不显示行聚类树
  cluster_columns = FALSE,    # 列不聚类
  show_column_names = FALSE,  # 不显示列名称
  show_row_names = FALSE,   # 行名
  col = heat.color,
  # 图例
  heatmap_legend_param = list(
    legend_height = unit(8,"cm"),
    title_position = "leftcenter-rot",
    title = NULL),
  right_annotation = hi,
  row_title = NULL,
  top_annotation = ha_top)

  