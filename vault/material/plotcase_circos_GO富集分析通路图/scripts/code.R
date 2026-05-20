library(devtools)
install_github("wencke/wencke.github.io")
library(GOplot)
library(tidyverse)

sessionInfo()

raw_go <- readr::read_tsv("GO_pathway.tsv", show_col_types = FALSE)
# 选择前 5 个通路（按 padj 最小）
process <- raw_go %>% arrange(`p.adjust`) %>% slice_head(n = 5) %>%
  pull(Description)
# 自定义 logFC 并筛选每个通路前 10 个基因
top_gene_per_term <- raw_go %>%
  filter(Description %in% process) %>%
  transmute(term = Description, padj = `p.adjust`,
            gene = stringr::str_split(stringr::str_to_upper(geneID), "/")) %>%
  tidyr::unnest(gene) %>%
  left_join(
    raw_go %>%
      filter(Description %in% process) %>%
      transmute(term = Description, padj = `p.adjust`,
                gene = stringr::str_split(stringr::str_to_upper(geneID), "/")) %>%
      tidyr::unnest(gene) %>%
      mutate(score = -log10(padj + 1e-300)) %>%
      group_by(gene) %>%
      summarise(raw = mean(score) * sqrt(n()), .groups = "drop") %>%
      mutate(logFC = as.numeric(scale(raw)), logFC = coalesce(logFC, 0)) %>%
      select(gene, logFC),
    by = "gene") %>%
  group_by(term) %>%
  arrange(desc(abs(logFC)), .by_group = TRUE) %>%
  slice_head(n = 10) %>% ungroup()

# 构建 GOplot 需要的 david 和 genelist
david <- raw_go %>%
  filter(Description %in% process) %>%
  transmute(
    Category = ONTOLOGY,
    ID = ID,
    Term = Description,
    adj_pval = `p.adjust`) %>%
  left_join(
    top_gene_per_term %>%
      group_by(term) %>%
      summarise(Genes = paste(unique(gene), collapse = ", "), .groups = "drop"),
    by = c("Term" = "term")) %>%
  filter(!is.na(Genes) & Genes != "")

genelist <- top_gene_per_term %>%
  distinct(gene, logFC) %>%
  transmute(ID = gene, logFC = round(as.numeric(logFC), 4)) %>%
  as.data.frame()

# 绘图
chord <- chord_dat(data = circle_dat(david, genelist), genes = genelist, process = process)
go_cols <- setNames(RColorBrewer::brewer.pal(length(process), "Set1"), process)
lims <- range(genelist$logFC, na.rm = TRUE)
brks <- pretty(lims, n = 4)

GOChord(chord,space = 0.02,gene.order = "logFC",
  gene.space = 0.25,gene.size = 3,
  ribbon.col = go_cols) +
  guides(shape = "none",
         size = guide_legend(title = "GO Terms",
      order = 1,ncol = 1,byrow = TRUE,
      override.aes = list(shape = 22, fill = unname(go_cols),
                          size = 6, color = "black")),
    fill = guide_colorbar(title = "logFC",order = 2,
                          title.position = "top",title.hjust = 0.5,
      barheight = unit(5, "cm"),
      barwidth = unit(0.5, "cm"))) +
  scale_fill_gradient2(name = "logFC",limits = lims,breaks = brks,
    labels = brks,low = "cornflowerblue",mid = "white",high = "brown1") +
  theme(
    legend.position = "right",
    legend.direction = "vertical",
    legend.box = "vertical")
