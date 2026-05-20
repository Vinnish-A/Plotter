library(tidyverse)

heatmap <- read.delim("data.tsv", header = TRUE)
# 取数值部分 + 行名
mat <- heatmap[, -1]
rownames(mat) <- heatmap[, 1]
# 按关键词拆分
score <- mat[, grepl("Escore$", colnames(mat))]
pval  <- mat[, grepl("_P$",     colnames(mat))]
# 至少一个疾病 P < 0.05
keep <- apply(pval < 0.05, 1, any)
heatmap_data <- score[keep, ]
p_vals       <- pval [keep, ]

df <- heatmap_data %>%
  rownames_to_column(var = "cell_TF") %>%
  pivot_longer(-cell_TF)

pval <- p_vals %>% rownames_to_column(var = "cell_TF") %>%
  pivot_longer(-cell_TF) %>%
  dplyr::rename("pval"="value") %>% select(pval)

dff <- df %>% bind_cols(pval) %>%
  mutate(sig_mat= case_when(
    pval < 0.05 & value > 3   ~ "**",
    pval < 0.05 & value > 1.5 ~ "*",
    TRUE ~ "")) %>% group_by(cell_TF) %>%
  mutate(scaled_TRS = scale(value)[, 1],
         name = str_remove(name, "_Escore$")) %>% ungroup() %>% 
  mutate(name=factor(name,levels = c("SLE","UC","IBD","PBC","RA")))

ggplot(data=dff,aes(name,cell_TF,fill=scaled_TRS)) +
  geom_tile(color="black") +
  geom_text(aes(label=sig_mat),color="black",vjust=0.7) +
  geom_point(
    data = dff %>% mutate(y=rep(1:57, each = 5),cell_TF = word(cell_TF, 1)) %>% 
      mutate(cell_type = str_extract(cell_TF, "^[^_]+")),
    aes(x = 0, y = rev(y), color = cell_type),
    size = 3,inherit.aes = FALSE) +
  scale_color_manual(
    values = c("B" = "#bcbddc","CD4+" = "#4eb3d3","CD8+" = "#238b45","mDCs" = "#8c6d31",
               "Monocytes" = "#b2182b","NK" = "#006d2c","pDCs" = "#7fcdbb"),
    labels = c("B" = "B cells","CD4+" = "CD4+ T cells","CD8+" = "CD8+ T cells",
      "mDCs" = "mDCs","Monocytes" = "Monocytes","NK" = "NK cells","pDCs" = "pDCs"),
    guide = guide_legend(
      theme = theme(legend.text = element_text(margin=margin(l=0,unit="cm")),
                    legend.title = element_blank()))) +
  scale_fill_gradientn(
    breaks = c(-1.5,-1,-0.5,0,0.5,1,1.5),
    guide = guide_colorbar(barheight = unit(5, "cm")),
    colors=colorRampPalette(rev(c( "firebrick3","#E77A77","#ECBA84","white","lightblue",'#336699')))(102)) +
  scale_y_discrete(position = "right",
                   limits = rev,
                   labels = function(x) str_remove(x, "^.*_")) +
  coord_cartesian(clip="off") +
  theme(
    plot.background = element_blank(),
    panel.background = element_blank(),
    axis.title = element_blank(),
    axis.text.y = element_text(color="black",size=8),
    axis.ticks = element_blank(),
    axis.text.x = element_text(
      angle = 35, hjust = 1, vjust = , size = 8,color="black"),
    legend.position = "right",
    legend.justification = c(0, 1),
    plot.margin = margin(0.5,0.5,0.5,1,unit="cm"))
  

