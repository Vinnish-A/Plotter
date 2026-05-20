library(tidyverse)
library(readxl)
library(ggrepel)
library(ggtext)
# install.packages("remotes")
# remotes::install_github("hughjonesd/ggmagnify")
library(ggmagnify)

sessionInfo()

df1 <- read_tsv("data.tsv")

genes_to_label <- c(
  "CD19","IGHM","IGHD","TBX21","ZEB2","MS4A1","ITGAX",
  "XBP1","DAPP1","S100A10","FCRL5","CXCR5","BCL2","TCF7",
  "BATF","CXCR3", "CXCR4")

plot <- ggplot(data=df1,aes(x = log2FoldChange, y = neg_log10_pvalue)) +
  geom_point(aes(color = regulation),
             stroke=0, alpha = 0.7,size = 2)+
  geom_hline(yintercept = -log10(0.05), 
             linetype = "dashed", color = "black")+
  geom_point(data = subset(df1,gene %in% genes_to_label), 
             aes(x = log2FoldChange, y = neg_log10_pvalue),
             color = "black", fill = NA, shape = 21, size = 2) +
  geom_text_repel(data = subset(df1, gene %in% genes_to_label), 
                  aes(label = gene), size = 3,max.overlaps = Inf) +
  annotate("segment",x = -0.5, xend = 0.5, y = 9, yend = 9,
           linewidth = 0.2,color = "black",
           arrow = arrow(ends = "both", type = "closed",
                         length = unit(0.25, "cm"))) +
  annotate( "text",x = -0.6, y = 9,label = "Up in\nyoung",  
            size = 3, color = "black") +
  annotate( "text",x = 0.6, y = 9,label = "Up in\nolder",  
            size = 3, color = "black") +

  coord_cartesian(clip="off") +
  scale_color_manual(values = c(
    "Up in OA" = "#bf812d", 
    "Up in YA" = "#35978f", 
    "Nominal Up in OA" = "#F3E4CD", 
    "Nominal Up in YA" = "#C3EAE7", 
    "Not significant" = "gray")) +  
  scale_x_continuous(limits = c(-0.75, 0.95)) +
  labs(title = "CD27- Effector Memory",x = "Log2 Fold Change",
       y = "-Log10 (p-value)",color = "Legend") +
  theme_classic() +
  theme(panel.grid =element_blank(),
        plot.title = element_text(
          vjust=0.5,hjust=0.5,size=10,color="black"),
        legend.position = "none",
        plot.margin = margin(0.5,6,0.5,0.5,unit="cm"))

plot + geom_magnify(from = c(-0.5,0,2.5,5),
             to = c(1.2,2.3,0,10),colour="red",
             proj = "facing",axes="xy")

