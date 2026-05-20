library(tidyverse)  
library(ggraph)  
library(igraph) 
BiocManager::install("BioNet")  
library(BioNet)       
library(readxl)  
sessionInfo()


# 1. 读取 STRING 背景网络
# 读取作者提供的 STRING NK 细胞背景网络（edge list 格式：gene1, gene2）
gene_network_NK_background = read.table('stringdb_NK_background.tsv', header = TRUE)
# 将 edge list 转换为 igraph 对象，后续用于 BioNet scoring
gene_network_NK_background = graph_from_data_frame(gene_network_NK_background)
# 删除自循环边（A-A），保证网络结构干净
gene_network_NK_background = rmSelfLoops(gene_network_NK_background)

# 2. 读取差异基因表（DEG_NK）
# 读取 Supplementary Data 中的 Sheet 3（DEG_NK），将 Gene 列设为行名
deg_NK <- read_excel("41590_2025_2341_MOESM4_ESM.xlsx",sheet = 3) %>% 
  column_to_rownames(var="Gene")


# 3. 准备 p 值向量（BioNet 输入）

pval = deg_NK$p_val_adj   
# 取每个基因的 FDR（padj），BioNet 用来计算节点显著性

names(pval) = rownames(deg_NK)
# 将基因名绑定到 p 值向量，BioNet 会用名称匹配节点

fb = fitBumModel(pval)
# 使用 BUM（Beta-Uniform mixture）模型拟合 p 值分布
# 输出 λ、a 等参数，表示“信号 + 噪声”混合结构

scores_all <- scoreNodes(network = gene_network_NK_background, fb = fb, fdr = 1e-6)
# 基于 BUM 模型计算每个节点的功能得分（functional node score）
# 分数越高表示越可能为真实信号；fdr=1e-6 非常严格，只保留高置信节点
scores_all <- scores_all[!is.na(scores_all)]
# 去掉 NA 分数，防止影响 Heinz 模块提取
# 4. 使用 Heinz 算法提取最高得分子网络（核心步骤）
module_NK <- runFastHeinz(network = gene_network_NK_background, scores = scores_all)
# Heinz = prize-collecting Steiner Tree 模型
# 在大背景网络中提取一个“得分总和最高”的最小连通子图（模块）
# 即 Fig.3d 中的 NK cell IFN hub

# 5. 将 log2FC 写回节点属性（用于可视化上色）
deg_NK_subset = subset(deg_NK, rownames(deg_NK) %in% as.character(V(module_NK)$name))
# 取被 Heinz 挑中的基因子集（模块成员）
logFC_NK = deg_NK_subset$avg_log2FC
names(logFC_NK) = rownames(deg_NK_subset)
# 准备一个 logFC 向量并绑定基因名称，后续写入节点属性
V(module_NK)$logFC = 0 
# 给所有节点初始化 logFC 属性
# 遍历模块节点，将真实 logFC 映射进去
for (node_name in names(logFC_NK)) {
  if (node_name %in% V(module_NK)$name) {
    node_id <- which(V(module_NK)$name == node_name)
    V(module_NK)$logFC[node_id] = logFC_NK[[node_name]]  
  }
}
# 6. 网络可视化（ggraph）
set.seed(100) # 固定随机布局，确保网络图可复现

ggraph(module_NK, layout = 'kk') +   # 'kk' = Kamada-Kawai 力导向布局
  geom_edge_link(edge_color = "grey",
                 aes(alpha = after_stat(index)),
                 show.legend = FALSE) +
  # 绘制边，使用透明度区分连通关系
  geom_node_point(aes(size = score, color = logFC)) +
  # 节点：大小 = BioNet node score；颜色 = log2FC
  scale_color_gradient2(low = "#75bca9",mid = "white",high = "#ef7923") +  
  # 自定义配色方案（绿色→白色→橙色），与原文 Fig.3d 保持一致
  geom_node_text(aes(label = name), repel = T, max.overlaps = Inf,
                 fontface = "italic", size = 4) +
  # 基因名标签，排斥重叠，使用斜体
  scale_size_continuous(name = "Functional \n Node \n Score") + 
  # 节点大小的图例标题（多行展示）
  theme_void() +  # 移除背景、坐标轴，只突出网络本身
  theme(plot.margin = margin(0.5,1,0.5,1,unit="cm"))
# 调整外边距，让标签不贴边