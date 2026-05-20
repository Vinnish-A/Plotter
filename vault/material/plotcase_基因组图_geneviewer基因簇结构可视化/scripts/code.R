install.packages("geneviewer")
library(geneviewer)

sessionInfo()

# 使用geneviewer 包内置的 ophA_clusters 数据
# 以基因起止坐标为横轴，按 class 着色、按 cluster 分面/分组绘制两个基因簇的结构
GC_chart(ophA_clusters, 
         start = "start",
         end = "end",
         group = "class",
         cluster = "cluster") %>%
  # 为每个基因簇添加物种名和基因座范围说明
  GC_clusterFooter(
    title = c("<i>Omphalotus olearius</i>", "<i>Dendrothele bispora</i>"), 
    subtitle = c("Locus: 2,522 - 21,484", "Locus: 19,236 - 43,005"),
    align = "left",
    x = 50) %>%
  # 图例放在顶部，并直接在基因箭头上显示基因名称
  GC_legend(position = "top") %>%
  GC_labels(label = "name") %>%
  # 添加比例尺；两个 cluster 使用不同坐标方向，第二个反向显示以方便同源区域对比
  GC_scaleBar(y = 20) %>%
  GC_scale(cluster = 1,  scale_breaks = TRUE, hidden = TRUE) %>%
  GC_scale(cluster = 2, reverse = TRUE, hidden = TRUE) %>%
  # 鼠标悬停时显示基因名和坐标范围，便于交互式查看细节
  GC_tooltip(
    formatter = "<b>Gene:</b> {name}<br> <b>Start:</b> {start}<br><b>end:</b> {end}")
