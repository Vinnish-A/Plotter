# 载入R包：
library(readxl)
library(circlize)
library(tidyverse)

sheets <- excel_sheets("NIHMS1854082-supplement-5.xlsx")

# 循环读取数据并处理：
for (i in 1:7) {
  tmp <- read_excel("NIHMS1854082-supplement-5.xlsx", sheet = i)[,2:3]

  if (i == 1) {
    data = tmp
  } else if (i == 7){
    tmp <- read_excel("NIHMS1854082-supplement-5.xlsx", sheet = i)[,c(2,13)]
    data <- merge(data, tmp, by = "node")
  } else {
    data <- merge(data, tmp, by = "node")
  }
}

# 由于最内层未找到对应数据，随机创建一组最内层（无实际意义）：
data$`Literature evidence` <- data$`DEG by RNA-seq`

data <- data %>% column_to_rownames("node")

data[is.na(data)] <- "N"
data <- data[,c(1:6,8,7)]

# 设置颜色模式：
col_fun = list(col_1 = c("Y" = "#ee5567", "N" = "#fbeaeb"),
               col_2 = c("Y" = "#fc6f53", "N" = "#faeee7"),
               col_3 = c("Y" = "#fdcb55", "N" = "#fdf7e8"),
               col_4 = c("Y" = "#9ed365", "N" = "#f2f9ea"),
               col_5 = c("Y" = "#4bdde7", "N" = "#e6f5fa"),
               col_6 = c("Y" = "#5e99e6", "N" = "#ebf3f9"),
               col_7 = c("Y" = "#7d66b7", "N" = "#eeedf4")
)


# 绘图：
{
  pdf("plot.pdf", height = 10, width = 10)
  circos.par$gap.degree <- 10
  circos.par$start.degree <- 85
  circos.par$track.margin <- c(0.001, 0.001)

  data_tmp <- as.matrix(data[,8])
  rownames(data_tmp) <- rownames(data)
  circos.heatmap.initialize(data_tmp, cluster = F)

  circos.track(
    ylim = c(0, 6),
    bg.border = NA,
    panel.fun = function(x, y){
      circos.barplot(data_tmp,
                     border = NA,
                     1:nrow(data_tmp) - 0.5,
                     col = "#b7a085")
      })

for (i in 1:7) {
  data_tmp <- as.matrix(data[,i])
  if (i == 1) {
    rownames(data_tmp) <- rownames(data)
  }
  colnames(data_tmp) <- colnames(data)[i]

  circos.heatmap(data_tmp,
                 col = col_fun[[i]],
                 rownames.side = "outside",
                 cluster = FALSE,
                 cell.border = "white",
                 track.height = 0.05)
}

circos.track(track.index = get.current.track.index(),
             panel.fun = function(x, y) {
  if(CELL_META$sector.numeric.index == 1) { # the last sector
    circos.rect(CELL_META$cell.xlim[2] + convert_x(1, "mm"), 0,
                CELL_META$cell.xlim[2] + convert_x(6, "mm"), 7,
                col = "#e5e8ed", border = NA)
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 0.5,
                "7", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 1.5,
                "6", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 2.5,
                "5", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 3.5,
                "4", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 4.5,
                "3", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 5.5,
                "2", cex = 0.5, facing = "inside")
    circos.text(CELL_META$cell.xlim[2] + convert_x(3.5, "mm"), 6.5,
                "1", cex = 0.5, facing = "inside")

  }
}, bg.border = NA)
circos.clear()
dev.off()
}



