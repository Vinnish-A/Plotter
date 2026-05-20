library(readxl)
library(tidyverse)
library(ggraph)
library(igraph)

df <- read_excel("43587_2025_1027_MOESM9_ESM.xlsx",sheet = 4) %>% 
  select(1,3) %>% filter(TF!=0)

gwas_genes <- c("PLXNA4","RUNX1T1","SOX6",
                "SCN2A","THSD7A","ZFHX3")

nodes <- tibble(name = unique(c(df$TF, df$Target))) %>%
  mutate(node_type = case_when(
      grepl("^rs", name) ~ "SNP",
      name == "FOXP2" ~ "TF",
      name %in% c("ASD","ADHD","SCZ","MDD","BIP") ~ "Disease",
      name %in% gwas_genes ~ "GWAS_Gene"),
    node_type = factor(
      node_type,
      levels = c("TF","Disease","GWAS_Gene","SNP")))

g <- graph_from_data_frame(
  d = df,vertices = nodes,directed = FALSE)

set.seed(123)

ggraph(g, layout = "fr") +
  geom_edge_link(colour = "grey75",width = 1.5) +
  geom_node_point(aes(size  = node_type,
                      color = node_type,
                      shape = node_type)) +
  geom_node_text(aes(label = name),
    repel = TRUE,size = 3,color="black") +
  scale_color_manual(values = c(
    TF= "#E64B35",Disease = "#F4C430",
    GWAS_Gene="#7E57C2",SNP= "#C7C3E6")) +
  scale_size_manual(values = c(
    TF=7,Disease =7,GWAS_Gene=7,SNP= 7)) +
  scale_shape_manual(values = c(
    TF= 17,  # 三角形
    Disease = 18,  # 菱形
    GWAS_Gene  = 16,SNP = 16)) +
  theme_void() +
  theme(legend.position = "none")