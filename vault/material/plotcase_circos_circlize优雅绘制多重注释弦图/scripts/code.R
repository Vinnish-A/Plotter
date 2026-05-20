library(tidyverse)
library(circlize)

df <- read_tsv("data.tsv") %>% column_to_rownames(var="id") %>% as.matrix()

mat1 <- df[1:4,1:4]
mat2 <- df[1:4,5:8]
mat3 <- df[5:8,5:8]
mat4 <- df[5:8,9:12]

set.seed(123)
par(bg = "white")

chordDiagram(df, annotationTrack = c("grid", "axis"), directional = 1, transparency = 0,
             preAllocateTracks = list( track.height = uh(4, "mm"), track.margin = c(uh(4, "mm"), 0) ))

circos.track(track.index = 2, panel.fun = function(x, y) {
  sector.index = get.cell.meta.data("sector.index")
  xlim = get.cell.meta.data("xlim")
  ylim = get.cell.meta.data("ylim")
  circos.text(mean(xlim), mean(ylim), 
              sector.index, col = "white", cex = 0.6, niceFacing = TRUE)})

highlight.sector(rownames(mat1), track.index = 1, col = "#FF8C00", text = "Chitwan", 
                       cex = 0.8, text.col = "white", niceFacing = TRUE)

highlight.sector(colnames(mat1),track.index = 1,
                 col = "#1E90FF", text = "Bardia", cex = 0.8, text.col = "white", niceFacing = TRUE)

highlight.sector(colnames(mat2),track.index = 1, col = "#90EE90", text = "Khaptad",
                 cex = 0.8, text.col = "white", niceFacing = TRUE)

highlight.sector(colnames(mat4),track.index = 1,col = "#E41A1C",text = "Suklaphata",
                 cex = 0.8, text.col = "white", niceFacing = TRUE)

circos.clear()


