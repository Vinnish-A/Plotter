library(tidyverse)	
library(circlize)
library(ComplexHeatmap)

sessionInfo()

df <- read_tsv("data.tsv") %>% 
  column_to_rownames(var="Taxon_name") %>% as.matrix()

color_map <- tibble::tribble(
  ~name,             ~color,
  "Day40",           "#E31A1C",
  "Day80",           "#228B22",
  "Day150",          "#1F78B4",
  "Day220",          "#FDB462",
  "Day300",          "#8B658B",
  "Day400",          "#4876FF",
  "Proteobacteria",  "blue",
  "Cyanobacteria",   "#ECCBAE",
  "Bacteroidetes",   "#924099",
  "Acidobacteria", "#d6cde2",
  "Planctomycetes", "#cce2e0",
  "Firmicutes",      "#f4d7d3",
  "Others",          "#f6e8c1",
  "Actinobacteria",  "#b4d2f4",
  "Chloroflexi",   "#b9e3c0",
  "Chlorophyta",     "#49c247")

# 转换为命名向量
col <- color_map %>% deframe()

circos.par(canvas.xlim=c(-0.3,1), canvas.ylim=c(-1.2,1.2), start.degree = 0)

chordDiagram(df,annotationTrack = c("grid"),
             grid.col = col)

circos.trackPlotRegion(track.index = 1, panel.fun = function(x, y) {
  circos.axis(h = "top", labels.cex = 0.5, major.tick.length = 0.1)
}, bg.border = NA)


# 定义一个包含扇区名称的向量 sector_labels
sector_labels <- c(colnames(df),rownames(df) %>% head(3),"Others")
# 将 sector_labels 向量的值赋予其名称，创建一个命名向量
names(sector_labels) <- sector_labels

circos.track(track.index = 2, ylim = c(0, 1), track.margin = c(0.02, 0.02),
             panel.fun = function(x, y) {
               sn_index <- as.character(CELL_META$sector.index)
               if (sn_index %in% names(sector_labels)) {
                 sn <- sector_labels[[sn_index]]
                 circos.text(CELL_META$xcenter, CELL_META$ylim[2] + mm_y(11),  # 向外偏移
                             sn, facing = "bending", niceFacing = TRUE,
                             adj = c(0.5, 0), cex=0.7)
               }
             }, bg.border = NA)

rowname <- tibble::tribble(
  ~name,             ~color,
  "Acidobacteria", "#d6cde2",
  "Planctomycetes", "#cce2e0",
  "Firmicutes",      "#f4d7d3",
  "Nitrospirae",      "#f6e8c1",
  "Actinobacteria",  "#b4d2f4",
  "Chloroflexi",   "#b9e3c0",
  "Chlorophyta",     "#49c247")


lab <- rowname %>% deframe()

graphics_list <- lapply(seq_along(lab), function(i) { 
  # 遍历 lab 的每个元素
  # 为每个扇区创建绘制点的函数，点的颜色来自 rowname
  function(x,y,w,h) grid.points(
    x,y,gp=gpar(col=lab[i],cex=1),pch=15)
})

lgd <- Legend(labels = names(lab), # 创建图例
              graphics = graphics_list, # 使用 graphics_list 中的绘图函数
              row_gap = unit(3, "mm")) # 设置图例行间距为 3 毫米
# 绘制图例，位置在画布的 x=0.9, y=0.2，底部对齐
draw(lgd, x = unit(0.85, "npc"),y = unit(0.2, "npc"),
     just = c("bottom"))