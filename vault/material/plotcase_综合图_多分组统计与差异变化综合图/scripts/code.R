library(tidyverse)
library(patchwork)
library(scales)
library(RColorBrewer)
library(readxl)

sessionInfo()

color_annotation <- read.csv('Cell_Type_Color_Annotation_and_Order.csv')

color_vector <- setNames(color_annotation$color,
                         color_annotation$label)


df1 <- read_excel("41586_2025_9686_MOESM5_ESM.xlsx",sheet = 3)

p1 <- ggplot(df1, aes(
  x=celltype, y=Genes_Tested, fill = celltype)) +
  geom_bar(stat="identity",width=0.8)+
  scale_y_continuous(expand = c(0,0)) +
  scale_fill_manual(values=color_vector)+
  theme_bw()+
  theme(legend.position="none",
        axis.text.y=element_text(color="black"),
        axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        plot.margin=grid::unit(c(0,0,-2.5,0), "mm")) +
  ylab('Genes\nTested')

df2 <- read_excel("41586_2025_9686_MOESM5_ESM.xlsx",sheet = 4)

p2 <- ggplot(df2, aes(
  x = celltype, y = count, fill = celltype)) +
  geom_bar(stat = "identity",width=0.8,aes(alpha=Expression) ) + 
  scale_fill_manual(values=color_vector)+
  labs(y = "DEG\nCounts", x = "Cell Type") +
  scale_alpha_manual(values = c(0.5, 1)) +
  scale_x_discrete(labels = function(x) gsub(" cell", "", x))+
  theme_bw()+
  theme(axis.title.x=element_blank(),
        axis.text.x=element_blank(),
        axis.ticks.x=element_blank(),
        axis.text.y=element_text(color="black"),
        legend.position="none",
        plot.margin=grid::unit(c(0,0,0,-.25), "mm"))

df3 <- read_excel("41586_2025_9686_MOESM5_ESM.xlsx",sheet = 5)

max_deg_number <- df3$total_count_clipped %>% max()

p3 <- ggplot(df3, aes(
  celltype, contrast, fill = total_count_clipped)) + 
  geom_tile() +
  scale_x_discrete(labels = function(x) gsub(" cell", "", x)) +
  scale_fill_gradientn(
    colours = c("white", brewer.pal(9, "Blues")[0:9]),
    values = rescale(
      c(0,seq(1, max_deg_number, length.out = 9))),
    limits = c(0, max_deg_number)) +
  theme_bw() +
  theme(legend.position = "bottom",
        axis.title.x=element_blank(),
        axis.text.x = element_text(
          color="black",angle = 90, vjust = 0.5, hjust = 1),
        legend.title.position = "top",
        legend.title = element_text(
          color="black",vjust=0.5,hjust=0.5),
        legend.key.width = unit(1,"null"),
        plot.margin = grid::unit(c(0, 0, 0, -0.25), "mm"))


(p1/p2/p3)+plot_layout(heights = c(1,2,1))
  
