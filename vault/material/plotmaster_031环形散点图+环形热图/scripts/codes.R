library(readxl)
library(tidyverse)

# 数据读取和简单预处理：
data <- read_excel("439_2022_2514_MOESM3_ESM.xlsx", sheet = 2, skip = 1) %>% 
  filter(`Outcome (ON) data source` == "FinnGen consortium") %>% 
  select(c(3,5,7,9,12,17,22,27,32)) %>% 
  as.data.frame()

data[1:5, 1:5]
# Level   ID                 IVW                ...9            MR Egger
# 1 phylum ID.1         0.313130556  1.3776680509999999 0.31554636699999999
# 2 phylum ID.2 0.55945944199999997 0.88998406900000004 0.87567043499999997
# 3 phylum ID.3 0.27339956500000001         1.258918749 0.58016842599999996
# 4 phylum ID.4         0.491187498  1.2233724619999999 0.79310948699999995
# 5 phylum ID.5 0.47413112299999999          1.17982074 0.64971595900000001

# 绘图:
library(circlize)

################### 外圈热图 ========================
# 设置颜色模式:
col_fun = list(col_1 = colorRamp2(c(0, 0.5, 1), 
                                  c("#ac90f4", "#8df4e6", "#e99651")),
               col_2 = colorRamp2(c(0, 1),
                                  c("#037b3d", "#55cbd7")),
               col_3 = colorRamp2(c(0, 0.5, 1),
                                  c("#15489c", "#fff403", "#e93832")),
               col_4 = colorRamp2(c(0, 1),
                                  c("#3c9d9d", "#cacaff")),
               col_5 = colorRamp2(c(0, 0.5, 1),
                                  c("#fe34cb", "#c0b892", "#6b396b"))
)


if (T) {
  pdf("plots.pdf", height = 6, width = 6)
  ################### 外圈热图 ========================
  circos.par("track.height" = 0.1,   # 每行的高度
             "start.degree" = 0,  # 环形开始的角度
             "gap.degree" = c(5, 5, 5, 5, 30), # sector之间的gap角度
             "track.margin" = c(0.01, 0.01))  # 每行之间的距离

  data_1 <- data[,-4]
  
  # 循环绘制热图：
  for (i in 1:6) {
    data_tmp <- as.matrix(as.numeric(data_1[, i+2]))
    if (i == 1) {
      rownames(data_tmp) <- data$ID
    }
    colnames(data_tmp) <- paste0(colnames(data_tmp), "-p")
    
    if (i < 6) {
      circos.heatmap(data_tmp, 
                     # 设置sector：
                     split = data$Level,
                     col = col_fun[[i]],
                     rownames.side = "outside", 
                     rownames.cex = 0.3,  # 行名字体大小
                     cluster = F,
                     cell.border = NA,  # 单元格边框
                     track.height = 0.05)
    } else {
      ################### 内圈散点图 ========================
      data_tmp <- as.matrix(as.numeric(data[, 4]))
      colnames(data_tmp) <- "IVM-OR"
      
      circos.track(ylim = range(data_tmp[,1]), 
                   panel.fun = function(x, y) {
                     # sector的名称：
                     circos.text(CELL_META$xcenter, 
                                 CELL_META$cell.ylim[2] + mm_y(1.5),
                                 CELL_META$sector.index,
                                 cex = 0.5
                     )
                     # y轴刻度：
                     circos.yaxis(labels.cex = 0.3, 
                                  at = seq(0.6, 1.8, 0.4), 
                                  sector.index = "phylum")
                     y = data_tmp[,1][CELL_META$subset]
                     y = y[CELL_META$row_order]
                     # 虚线：
                     circos.lines(CELL_META$cell.xlim, c(1, 1), lty = "dashed", col = "black")
                     # 散点：
                     circos.points(seq_along(y) - 0.5, y, 
                                   pch = 16, cex = 0.5,
                                   col = "#63caff")
                     # 行名：
                     if(CELL_META$sector.numeric.index == 5) { # the last sector
                       cn = rev(c("IVM-p", "MR Egger-p", "WM-p", "MLE-p","MR RAPS-p", "IVM-OR"))
                       n = length(cn)
                       circos.text(rep(CELL_META$cell.xlim[2], n) + convert_x(8, "mm"), 
                                   c(1, seq(3.5, 9.5, 1.5)), cn, 
                                   cex = 0.5, adj = 0.5, facing = "inside")
                     }
                   }, 
                   track.margin = c(0.02, 0.02),
                   cell.padding = c(0.02, 0, 0.02, 0))
    }
  }
  circos.clear()
  dev.off()
}




