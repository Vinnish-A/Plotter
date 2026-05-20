library(tidyverse)
library(igraph)
library(ggraph)

sessionInfo()

example2_edges <- read_tsv("OPPP_edges.tsv")
example2_nodes <- read_tsv("OPPP_nodes.tsv")

example2_nodes <- example2_nodes %>% 
  mutate(label = str_remove(name, "_\\d"))

example2_network <- graph_from_data_frame(
  d = example2_edges,
  vertices = example2_nodes,
  directed = T)

ggraph(example2_network, layout = "kk") +
  geom_node_point(size = 3, aes(fill = as.factor(carbons)), 
                  alpha = 0.8, shape = 21, color = "grey20") +
  geom_node_text(aes(label = label), hjust = 0.5, repel = T) +
  geom_edge_link(label_dodge = unit(2, 'lines'),
    arrow = arrow(length = unit(0.4, 'lines')), 
    start_cap = circle(1, 'lines'),
    end_cap = circle(2, 'lines')) +
  labs(fill = "Carbons") +
  theme_void()  

