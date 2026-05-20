library(circlize)
library(viridis)
library(reshape2)
library(ComplexHeatmap)
library(grid)

sessionInfo()
#info dataset
df <- read.csv("circle.CSV", header=TRUE,stringsAsFactors = FALSE,check.names = FALSE)
df_melt<-melt(df,id.vars = 'Type')
colnames(df_melt)<-c('from','to','value')
df_melt$to<-as.character(df_melt$to)

#define factor
df_sum<-apply(df[,2:ncol(df)],2,sum)+apply(df[,2:ncol(df)],1,sum)
order<-sort(df_sum,index.return=TRUE,decreasing =TRUE)
df_melt$from<-factor(df_melt$from,levels=df$Type[order$ix],order=TRUE)

df_melt <-dplyr:: arrange (df_melt, from)
#define color
mycolor = c(Aliphatic="#81D1DA",Amino="#D4D7D5",
            Carbohydrate="#CE99FF",
            Aromatic="#FFC8D4",
            Phenolic="#F9F93E",
            Lignin="#FFC284",
            Lipid="#68ACCF",
            Polyphenol="#76EEAB",
            Protein="#FFA98F",
            Tannin="#00CD66",
            Acidobacteria="#E4F2E4",
            Actinobacteria="#94EED0",
            Bacteroidetes="#EE8B78",
            Chloroflexi="#A58BDB",
            Cyanobacteria="#ADD8E6",Firmicutes="#EEE685",
            Gemmatimonadetes="#FFD700",Planctomycetes="#EEEED1",
            Alphaproteobacteria="#51A0EE",Betaproteobacteria="#69B5FF",
            Deltaproteobacteria="#8ACAFF",Gammaproteobacteria="#B1D8FF",
            Verrucomicrobia="#DAA520")
#circos plot
circos.clear()
circos.par(start.degree = 90, gap.degree = 4, track.margin = c(-0.1, 0.1),
           points.overflow.warning = FALSE,
           canvas.xlim=c(-0.5,1), canvas.ylim=c(-1,1))

chordDiagram(
  x = df_melt,
  grid.col = mycolor,
  order = c("Aliphatic","Amino",
            "Carbohydrate","Aromatic",
            "Phenolic","Lignin","Lipid",
            "Polyphenol","Protein","Tannin",
            "Acidobacteria","Actinobacteria",
            "Bacteroidetes","Chloroflexi",
            "Cyanobacteria","Firmicutes",
            "Gemmatimonadetes","Planctomycetes",
            "Alphaproteobacteria","Betaproteobacteria",
            "Deltaproteobacteria","Gammaproteobacteria",
            "Verrucomicrobia"),
  transparency = 0.65,
  directional = 1,
  direction.type = c("arrows", "diffHeight"),
  diffHeight = -0.04,
  annotationTrack = "grid",
  annotationTrackHeight = c(0.05, 0.1),
  link.arr.type = "big.arrow",
  link.sort = TRUE,
  link.largest.ontop = TRUE)

sector_names <- get.all.sector.index()  # 所有扇区名
number_labels <- as.character(1:length(sector_names))  # 数字 1 到 32（或根据扇区数量自动生成）

for (i in seq_along(sector_names)) {
  si <- sector_names[i]
  xlim <- get.cell.meta.data("xlim", sector.index = si, track.index = 1)
  ylim <- get.cell.meta.data("ylim", sector.index = si, track.index = 1)

  circos.text(mean(xlim), ylim[1],
              labels = number_labels[i],  # 用数字标签替换扇区名
              sector.index = si,
              track.index = 1,
              facing = "inside",
              cex = 0.7, adj = c(0.5,-0.5), niceFacing = T)
}

col_values <- mycolor
graphics_list <- lapply(seq_along(col_values), function(i) {
  function(x, y, w, h) {
    grid.rect(x, y, width = w, height = h,
              gp = gpar(fill = col_values[i], col = NA))  # 背景色块
    grid.text(label = as.character(i), x = x, y = y,
              gp = gpar(col = "black", fontsize =8))    # 白字数字
  }
})

lgd <- Legend(labels = names(col_values), # 创建图例，标签为 col_values 的名称
              graphics = graphics_list, # 使用 graphics_list 中的绘图函数
              row_gap = unit(2, "mm"),
              labels_gp = gpar(col = "black",fontsize =8))

draw(lgd, x = unit(0.88, "npc"),
     y = unit(0.1, "npc"), just = c("bottom"))




