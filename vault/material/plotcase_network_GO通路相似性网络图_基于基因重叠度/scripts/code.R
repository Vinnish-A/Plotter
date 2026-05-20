library(tidyverse)
library(ggraph)
library(ggforce)
library(igraph)
library(RColorBrewer)
library(ggtext)

df <- read_tsv("GO_pathway.tsv")

pathways <- setNames(strsplit(as.character(df$geneID), "/"),
                     df$Description)
# 计算 Jaccard 相似度矩阵
pw_names <- names(pathways)
n <- length(pathways)
jaccard_mat <- matrix(0, n, n, dimnames = list(pw_names, pw_names))

for(i in 1:n){
  for(j in 1:n){
    inter <- length(intersect(pathways[[i]], pathways[[j]]))
    union <- length(union(pathways[[i]], pathways[[j]]))
    jaccard_mat[i,j] <- ifelse(union > 0, inter/union, 0)
  }
}


edges <- which(jaccard_mat > 0 & upper.tri(jaccard_mat), arr.ind = TRUE)
edge_df <- data.frame(
  from = rownames(jaccard_mat)[edges[,1]],
  to   = colnames(jaccard_mat)[edges[,2]],
  Similarity = jaccard_mat[edges]) %>% 
  mutate(Similarity_class = cut(
    Similarity,breaks=c(0,0.04,0.08,0.12,0.16,1)))
# 整合边文件
g <- graph_from_data_frame(edge_df,
  directed = FALSE,
  vertices = df %>% select(name = Description, Count, `p value`))
# 构建背景圆
coords <- ggraph(g, layout = "circle")$data
center_x <- mean(range(coords$x))
center_y <- mean(range(coords$y))
radius   <- max(sqrt((coords$x - center_x)^2 + (coords$y - center_y)^2)) * 1

ggraph(g,layout = 'linear',circular = TRUE) +
  # 背景圆
  geom_circle(aes(x0 = center_x, y0 = center_y, r = radius),
               inherit.aes = FALSE, fill = "lightblue", alpha = 0.04, color = NA) +
  geom_edge_arc(aes(width = Similarity,linetype = Similarity_class),
                alpha = 0.5, colour = "black") +
  geom_node_point(aes(size = Count, color = `p value`)) +
  geom_node_text(aes(label = name), repel = TRUE, size = 3, vjust =2) +
  scale_edge_width(range = c(0.5,1.5)) +
  scale_size_continuous(range = c(4,8)) +
  scale_edge_linetype_manual(values = c("dotted","dotdash","dotted","dotted")) +
  scale_color_gradientn(colors=colorRampPalette(brewer.pal(9,"Greens")[4:8])(50)) +
  guides(edge_linetype = "none") +
  labs(title="The metascape pathways of<br>
       upregulated DEGs and DEPs (EVs<sup>ABPC</sup>versus EVs<sup>F-BMSC</sup>)") +
  theme_void() +
  theme(legend.position = "right",
        plot.title = element_markdown(vjust=0.5,hjust=0.5,color="black",size=11),
        plot.margin = margin(0.5,1,0.5,0.5,unit="cm"))

