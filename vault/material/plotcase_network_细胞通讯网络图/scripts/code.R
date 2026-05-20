library(tidyverse)
library(CellChat)
library(igraph)
library(grid)


count_net <- read.delim("count_network.txt", check.names = FALSE)
#devtools::install_github("jinworks/CellChat")

count_inter <- count_net
#count_inter$count <- count_inter$count/100
count_inter$count <- count_inter$count


count_inter<- spread(count_inter, TARGET, count)
rownames(count_inter) <- count_inter$SOURCE
count_inter <- count_inter[, -1]
count_inter <- as.matrix(count_inter)


count_inter <- count_inter[,c("CD8+ Exhausted T","CD56brightCD16- NK cells",
                              "Treg","CD56dimCD16+ NK cells","MAIT",
                              "gd T","C2: C1q+IL18+MCs",
                              "Plasma cells","CD8+ GZMK+ T",
                              "B cells","Naive T","CD8+ GZMB+ T")]

count_inter <- count_inter[c("CD8+ Exhausted T","CD56brightCD16- NK cells",
                             "Treg","CD56dimCD16+ NK cells","MAIT",
                             "gd T","C2: C1q+IL18+MCs","Plasma cells",
                             "CD8+ GZMK+ T","B cells","Naive T","CD8+ GZMB+ T"),]

node.colors <- c("CD8+ Exhausted T" = "pink" ,"CD56brightCD16- NK cells"="#8491B4FF",
                 "Treg"="#F39B7FFF","CD56dimCD16+ NK cells"="#3C5488FF",
                 "MAIT" = "#DC0000FF","gd T"="#E64B35FF",
                 "C2: C1q+IL18+MCs" = "black",
                 "Plasma cells"="#B09C85FF","CD8+ GZMK+ T"="#91D1C2FF",
                 "B cells"="#7E6148FF","Naive T"="#4DBBD5FF",
                 "CD8+ GZMB+ T"="#00A087FF")


edge.colors <- rep("purple", nrow(count_inter))
names(edge.colors) <- rownames(count_inter)


igraph.options(vertex.color = node.colors)


netVisual_circle(count_inter,
                 weight.scale = TRUE,
                 sources.use = "C2: C1q+IL18+MCs",
                 arrow.size = 0.2,
                 vertex.label.cex = 1,
                 vertex.label.color = "black",
                 alpha.edge = 0.8,
                 edge.curved = TRUE,
                 shape = "circle")





