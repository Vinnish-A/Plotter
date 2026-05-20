library(tidyverse)
library(circlize)
library(ComplexHeatmap)

# 导入数据
data.df <- read_tsv("data.tsv") %>% column_to_rownames(var="sample") %>% t()

# 聚类分析并将结果转换为树文件
dend_list <- as.dendrogram(hclust(dist(t(data.df))))

# 定义调色板
col_fun = colorRamp2(breaks= c(-13.288,-5.265,-6.674,-2.544,4.694,5.000), 
                     color=c("#2166AC","#4393C3","#92C5DE","#FDDBC7","#F4A582","#D6604D"))

# 定义布局
circos.clear()
circos.par("start.degree" = 90,cell.padding = c(0, 0, 0, 0), gap.degree = 15) 
circos.initialize("a", xlim =c(0,100)) 

# 绘制外圈文本
circos.track(ylim = c(0, 1), bg.border = NA, track.height = 0.05, 
             panel.fun = function(x, y) {
               for(i in seq_len(ncol(data.df))) {
                 circos.text(i-0.5, 0, colnames(data.df)[order.dendrogram(dend_list)][i], adj = c(0, 0.5), 
                             facing = "clockwise", niceFacing = TRUE,
                             cex = 0.7)                
               }
             })

# 绘制色块并添加分组文本
circos.track(ylim = c(0, 2), bg.border = NA, panel.fun = function(x, y) {
  m2 = data.df[, order.dendrogram(dend_list)]
  col_mat = col_fun(m2)
  nr = nrow(m2)
  nc = ncol(m2)
  for(i in 1:nr) {
    circos.rect(1:nc - 1, rep(nr - i, nc), 
                1:nc, rep(nr - i + 1, nc), 
                border = col_mat[i, ], col = col_mat[i, ])
  }
  circos.text(rep(1, 2),1:2, 
              rownames(data.df), 
              facing = "downward",adj = c(2.2,2), cex = 0.7) 
  })

max_height = attr(dend_list,"height") # 提取树高
# 添加聚类树
circos.track(ylim = c(0, max_height), bg.border = NA, track.height = 0.3, 
             panel.fun = function(x, y) {
               dend = dend_list
               circos.dendrogram(dend, max_height = max_height)
             })
circos.clear()

# 绘制图例

lgd <- Legend(at=c(-15,-5,0,5),col_fun = col_fun,legend_width = unit(4,"cm"),
                   title_position = "topleft", title = "Value", direction = "horizontal")

# 设置图例位置
draw(lgd,x = unit(0.5,"npc"),y = unit(0.5,"npc")) 
