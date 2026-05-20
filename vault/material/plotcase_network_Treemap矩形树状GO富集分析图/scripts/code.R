library(tidyverse)
library(clusterProfiler)
library(org.Hs.eg.db)
#BiocManager::install("rrvgo")
library(rrvgo)
library(treemapify)

sessionInfo()

# 输入文件
master_file <- "Source_data_master_file_FT_cilia_proteome.tsv"
universe_file <- "Source_data_background_gene_universe.tsv"

# 分析参数
p_adjust_cutoff <- 0.01
qvalue_cutoff <- 0.05
similarity_threshold <- 0.7

# 读取目标基因和背景基因集。
# enrichGO() 需要的是 Ensembl ID 字符向量，而不是单列表格。
master <- read_tsv(master_file, show_col_types = FALSE)
target_genes <- master |> pull(ensg_id) |> unique() |>
  na.omit()

background_genes <- read_tsv(universe_file, show_col_types = FALSE) |>
  pull(1) |> unique() |>na.omit()

# 对单个 GO ontology 执行富集分析，可选 BP、CC 或 MF。
run_go <- function(genes, universe, ont) {
  enrichGO(
    gene = genes,
    universe = universe,
    keyType = "ENSEMBL",
    OrgDb = org.Hs.eg.db,
    ont = ont,
    pAdjustMethod = "BH",
    pvalueCutoff = p_adjust_cutoff,
    qvalueCutoff = qvalue_cutoff,
    readable = TRUE)
}

# 将 enrichResult 对象转换为普通数据框，并保留 ontology 标签。
go_results <- list(
  BP = run_go(target_genes, background_genes, "BP"),
  CC = run_go(target_genes, background_genes, "CC"),
  MF = run_go(target_genes, background_genes, "MF"))

dataGO <- imap_dfr(go_results, \(result, ont) {
  if (is.null(result)) {
    return(tibble())
  }

  as_tibble(result@result) |>
    mutate(Type = ont)
})

# 在每个 ontology 内根据语义相似性合并冗余 GO term。
# rrvgo 会把相似 term 分组，并保留代表性的 parent term。
reduce_go <- function(data, ont_label) {
  terms <- data |>
    filter(Type == ont_label, p.adjust < p_adjust_cutoff) |>
    transmute(
      GO = str_extract(ID, "GO:\\d+"),
      P = p.adjust) |> drop_na(GO, P)

  if (nrow(terms) == 0) {
    return(tibble())
  }

  sim_matrix <- calculateSimMatrix(
    terms$GO,
    orgdb = "org.Hs.eg.db",
    ont = ont_label,
    method = "Rel")

  reduced_terms <- reduceSimMatrix(
    sim_matrix,
    scores = setNames(-log10(terms$P), terms$GO),
    threshold = similarity_threshold,
    orgdb = "org.Hs.eg.db")

  as_tibble(reduced_terms) |>
    mutate(Go.col = ont_label)
}

df.all <- map_dfr(c("BP", "CC", "MF"), \(ont) reduce_go(dataGO, ont)) |>
  group_by(parentTerm) |>
  mutate(n = row_number(),
    m = 1 - size / max(size)) |> ungroup()

# 每类 GO ontology 的基础颜色。
ontology_pal <- enframe(
  c("MF" = "#FF6F00", "CC" = "#C71B00", "BP" = "#018EA0"),
  name = "Go.col",value = "color")

# 为同一个 parent 下的不同 term 生成轻微深浅变化的颜色。
spread_colors <- function(color, n, colorrange = 0.5) {
  if (n == 1) {
    return(color)
  }

  rgb_matrix <- colorRamp(c("white", color, "black"))(
    seq(0.5 - colorrange / 2, 0.5 + colorrange / 2, length.out = n)
  )

  rgb(rgb_matrix[, 1], rgb_matrix[, 2], rgb_matrix[, 3], maxColorValue = 255)
}

# 绘制去冗余后的 GO term treemap。
go_plot <- df.all |>
  left_join(ontology_pal, by = "Go.col") |>
  group_by(parent) |>
  mutate(color2 = spread_colors(unique(color), n_distinct(go), colorrange = 0.2)) |>
  ungroup() |>
  ggplot(aes(area = score, subgroup = parentTerm)) +
  geom_treemap(aes(fill = color2), color = "black", show.legend = TRUE) +
  geom_treemap_subgroup_border(color = "black") +
  geom_treemap_text(aes(label = term),
    colour = "black",place = "centre",alpha = 0.4,grow = TRUE) +
  geom_treemap_subgroup_text(place = "centre",grow = TRUE,
    reflow = TRUE,alpha = 1,colour = "white",fontface = "bold",
    min.size = 0) +
  scale_fill_identity() +
  theme_void()

go_plot
