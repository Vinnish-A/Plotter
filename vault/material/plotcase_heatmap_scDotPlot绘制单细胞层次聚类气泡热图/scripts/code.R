# 如未安装相关包，可先取消注释并运行下面的安装命令
#BiocManager::install("scDotPlot")
# BiocManager::install("scRNAseq")
# BiocManager::install("scran")

# 加载示例数据、单细胞预处理、marker 计算和绘图所需的 R 包
library(scRNAseq)
library(scuttle)
library(scDotPlot)
library(ggsci)
library(scran)
library(tidyverse)
library(AnnotationDbi)

sessionInfo()

# 读取 scRNAseq 包内置的 Zeisel 小鼠脑单细胞数据集
sce <- ZeiselBrainData()

# 对表达矩阵进行 log 标准化，并去除未被注释到具体 level2class 的细胞
sce <- sce |> 
  logNormCounts() |>  
  subset(x = _, , level2class != "(none)")

# 按一级细胞类型 level1class 计算 marker 基因评分；
# 每个一级细胞类型选取 mean.AUC 最高的前 6 个基因用于后续展示
features <- sce |>
  scoreMarkers(sce$level1class) |>
  map(~ .x |>
        as.data.frame() |>
        arrange(desc(mean.AUC))|>
        dplyr::slice(1:6) |>
        rownames()) |> 
  unlist2()

# 将筛选出的 marker 基因写入 rowData，作为气泡图顶部的基因注释信息
rowData(sce)$Marker <- features[match(rownames(sce), features)] |>
  names()

# 绘制单细胞层次聚类气泡热图：
# 点的颜色表示平均表达量，点的大小表示表达该基因的细胞比例；
# 行方向按 level2class 展示更细的细胞亚群，并用 level1class 添加分组注释
sce |>
  scDotPlot(features = features,
            group = "level2class",
            groupAnno = "level1class",
            featureAnno = "Marker",
            groupLegends = FALSE,
            annoColors = list("level1class" = pal_d3()(7),
                              "Marker" = pal_d3()(7)),
            annoWidth = 0.02)
