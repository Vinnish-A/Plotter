library(tidyverse)
library(ggraph)
library(igraph)
library(tidygraph)
# 读取并处理数据
ppi_df <- read_delim(file = "string_interactions.tsv",
                     delim = "\t",col_names = TRUE)
# 创建边列表
edge_list <- ppi_df %>%
  select(node1, node2, combined_score) %>%
  rename(from = node1,to = node2,
    value = combined_score)
# 构建网络图数据集
graph_df <- as_tbl_graph(edge_list) %>%
  tidygraph::mutate(
    Popularity = centrality_degree(mode = 'all'),
    Betweenness = centrality_betweenness(),
    Degree = case_when(
      Popularity >= 5 ~ "High",
      TRUE ~ "Low")) %>% 
  activate(edges) %>%
  mutate(Interaction = case_when(
      value > 0.8 ~ "Strong",
      TRUE ~ "Weak"))

ggraph(graph_df, layout = 'linear', circular = TRUE) +
  # 添加连续边线
  geom_edge_arc(aes(color = Interaction, width = value/1000)) +
  # 添加节点
  geom_node_point(aes(size = Popularity,fill = Degree),
                  color = "#000000",alpha = 1, shape = 21) +
  # 添加文本
  geom_node_text(aes(label=name,x=x*1.07,y=y*1.07,
                     angle=-((-node_angle(x,y)+90) %% 180)+ 90,
                     vjust=0.5,hjust=ifelse(x>0,0,1)),size=3) +
  # 定义边线的颜色
  scale_edge_colour_manual(
    values = c("Strong" = "#E7298A","Weak"   = "#F4A6B7")) +
  scale_edge_width(range = c(0.1, 1)) +
  scale_size_continuous(range = c(1, 8)) +
  scale_fill_manual(values = c("High" = "#7FCDBB","Low"  = "#F2F2F2")) +
  guides(size = "none",edge_width = "none") +
  labs(caption = "Strong interaction: combined score > 0.8") +
  coord_cartesian(clip="off") +
  theme_graph() +
  theme(legend.position = "right",
    plot.title = element_text(size = 14, face = "bold", hjust = 0.5),
    legend.text = element_text(size =12,color="black"),
    plot.caption = element_text(vjust=0,hjust=0.5,color="black",size=12))

