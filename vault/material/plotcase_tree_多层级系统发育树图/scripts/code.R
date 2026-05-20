library(tidyverse)
library(ggtree)
library(ggtreeExtra)
library(ape)
library(RColorBrewer)
library(ggnewscale)

# 读取数据
BacTree  <- read.tree("pMAGs_bact_gtdtk_midroot.tree")
dat      <- read_tsv("pMAGS_tax.tsv")
dataset  <- read_tsv("pMAGS_Presence_Datasets.txt")
covmax   <- read_tsv("pMAGs_cov_sum.txt")
# 处理 taxonomy
dat <- dat %>% mutate(
    p_c = if_else(p == "p__Proteobacteria", c, p),
    p_c = gsub(".__|_.$", "", p_c))
# 细菌数据
bacDat <- dat %>% filter(d == "d__Bacteria") %>%
  mutate(Abundance = 0.2)
# 选择最丰富分类
tax_list <- bacDat %>% count(p_c, sort = TRUE) %>%
  slice_head(n = 16) %>% pull(p_c) %>% c("Nitrospirota")

bacDat <- bacDat %>%
  mutate(p_c = if_else(p_c %in% tax_list, p_c, "Other"))
# Dataset 信息
bacDatset <- dataset %>% filter(MAGs %in% bacDat$MAGs) %>%
  mutate(
    Busi     = gsub("Busi", "Busi et al., Nat Com, 2022", Busi),
    ENSEMBLE = gsub("ENSEMBLE", "Michoud et al, L&O, 2023", ENSEMBLE),
    Tibet    = gsub("Tibet", "Tibetan Glacier Genome and Gene", Tibet),
    Tara     = gsub("Tara", "Tara Oceans", Tara)) %>%
  column_to_rownames("MAGs")
# abundance
bactcov <- covmax %>% filter(MAGs %in% bacDat$MAGs) %>%
  select(MAGs, count) %>%
  mutate(count = log10(count)) %>%
  column_to_rownames("MAGs")


# tree group
a <- split(bacDat$MAGs, bacDat$p_c)
tree <- groupOTU(BacTree, a)
# 颜色
getPaletteBact <- colorRampPalette(brewer.pal(9, "Set1"))
bactColor <- getPaletteBact(length(unique(bacDat$p_c)) + 1)
bactColor[1] <- "black"
# Tree
p1 <- ggtree(tree, layout = "circular", aes(color = group)) +
  geom_tree() +
  geom_treescale(width = 0.1) +
  scale_color_manual(values = bactColor, na.value = "transparent", guide = "none") +
  theme_tree()
# Taxonomy bar
p2 <- p1 +
  new_scale_colour() + new_scale_fill() +
  geom_fruit(data = bacDat,geom = geom_bar,
    mapping = aes(y = MAGs, fill = p_c, x = 1),
    stat = "identity",pwidth = 0.01) +
  scale_fill_manual(values = bactColor[-1]) +
  labs(fill = "Taxa") +
  new_scale_colour() + new_scale_fill()
# Dataset heatmap
p3 <- gheatmap(p2, bacDatset,width = 0.2,
  offset = 0.1,colnames = FALSE,color = NULL) +
  scale_fill_discrete(na.translate = FALSE) +
  labs(fill = "Datasets") +
  new_scale_colour() + new_scale_fill()
# abundance heatmap
p4 <- gheatmap(p3, bactcov,offset = 0.6,width = 0.05,
  colnames = FALSE,color = NULL) +
  scale_fill_viridis_c() +
  labs(fill = "Normalized log10\nabundance")

p4

