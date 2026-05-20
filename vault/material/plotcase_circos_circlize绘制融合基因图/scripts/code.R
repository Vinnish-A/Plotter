library(tidyverse)
library(circlize)

sessionInfo()

bed <- read_tsv("bed.tsv", show_col_types = FALSE)
link1 <- read_tsv("link1.tsv", show_col_types = FALSE)
link2 <- read_tsv("link2.tsv", show_col_types = FALSE)

chromosomes <- paste0("chr", c(1:22, "X", "Y"))
link_cols <- c(red = "red", green = "#0B775E")

circos.clear()
on.exit(circos.clear(), add = TRUE)

circos.par(gap.after = c(rep(1, length(chromosomes) - 1), 0), start.degree = 90)
circos.initializeWithIdeogram(species = "hg19", plotType = NULL)

circos.genomicLabels(
  bed,
  labels.column = "geneID",
  side = "outside",
  connection_height = 0.1,
  labels.side = "clockwise"
)

set_track_gap(mm_h(0.1))

circos.track(
  ylim = c(0, 1),
  track.height = 0.05,
  bg.border = "white",
  panel.fun = function(x, y) {
    sector <- CELL_META$sector.index

    if (sector %in% chromosomes) {
      circos.text(
        CELL_META$xcenter,
        CELL_META$ylim[2],
        sector,
        cex = 0.5,
        facing = "inside",
        niceFacing = TRUE,
        adj = c(0.5, 0.5),
        col = "black"
      )
    }
  }
)

circos.genomicIdeogram(track.height = mm_h(2))

walk(names(link_cols), function(group) {
  circos.genomicLink(
    link1 %>% filter(col == group),
    link2 %>% filter(col == group),
    col = link_cols[[group]]
  )
})
