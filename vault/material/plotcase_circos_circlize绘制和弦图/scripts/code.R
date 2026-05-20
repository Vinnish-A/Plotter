library(tidyverse)
library(readxl)
library(circlize)
library(MetBrewer)
library(magrittr)
library(grid)
library(gridtext)

# 此部分统计得出两个数值，即图中的ns与nd。

read_excel("43018_2024_870_MOESM8_ESM.xlsx",sheet = 1) %>% 
  filter(from == to) %>% select(value) %>% sum()

read_excel("43018_2024_870_MOESM8_ESM.xlsx",sheet = 1) %>% 
  filter(from != to) %>% select(value) %>% sum()

dff <- read_excel("43018_2024_870_MOESM8_ESM.xlsx",sheet = 1)


circos.clear() 
circos.par(canvas.xlim=c(-1,0.8),canvas.ylim=c(-1,1),start.degree = -90)

link.colors <- ifelse(
  dff$from == dff$to,                  # 第一条件：起点和终点相同
  "white",                             # 满足条件时设置为白色
  ifelse(dff$gp70 == "pos", "red", "blue") # 第二条件：根据 gp70 设置颜色
)

# 为每一个组织构建颜色
grid.col1 <- c(dff$to %>% unique(),dff$from %>% unique()) %>% as.data.frame() %>%
  bind_cols(c(paste(met.brewer("VanGogh2")),
              paste(met.brewer("Monet")),
              paste(met.brewer("Egypt")),
              paste(met.brewer("Archambault")),
              paste(met.brewer("Cassatt1")),
              paste(met.brewer("Cassatt2"))) %>%
              as.data.frame() %>% head(36)) %>%
  set_colnames(c("name","col"))
# 颜色进行映射
grid.col <- grid.col1 %>% deframe() 
#绘制和弦图
chordDiagram(dff,
             link.sort = F,
             link.decreasing = TRUE, 
             transparency =0.4,
             col = link.colors, 
             grid.col = grid.col,
             annotationTrack = c("grid", "axis"),
             annotationTrackHeight = mm_h(c(5,1)))
# 定义需要展示的标签
sector_labels <- c("Ccl5.1","Cytotox.1","Slamf6")

names(sector_labels) <- sector_labels

circos.track(track.index = 1, panel.fun = function(x, y) {
  sn_index <- as.character(CELL_META$sector.index)
  if (sn_index %in% names(sector_labels)) {
    sn <- sector_labels[[sn_index]]
    circos.text(CELL_META$xcenter, CELL_META$ycenter, sn,col = "black",
                font = 1, cex = 0.8, adj = c(0.5,-4
                                             ), niceFacing = TRUE)
    xlim = CELL_META$xlim
    breaks = seq(0, xlim[2], by = 4e5)
  }
}, bg.border = NA)

# 添加标题与注释
title("Anti-PD-L1", cex.main  =1)

richtext_grob <- richtext_grob(
  text = "n<sub>S</sub>=1962,n<sub>D</sub>=1508",
  x = 0.55, 
  y = 0.02,
  gp = gpar(fontsize = 10)
)
grid.draw(richtext_grob)