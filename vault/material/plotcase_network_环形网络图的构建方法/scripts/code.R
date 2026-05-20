library(tidyverse)
library(readxl)
library(igraph)
library(ggraph)

sessionInfo()

df <- read_excel("41588_2025_2326_MOESM8_ESM.xlsx",sheet = 3, skip = 1)
# 定义函数拆分数据
split <- function(x){
  tibble(
    gene = str_extract(x, "^[^.]+"),
    category = str_replace(x, "^[^.]+\\.", ""))
}

from <- split(df$from)
to   <- split(df$to)
# 每条边的两端 gene 必须相同
stopifnot(all(from$gene == to$gene))

edges <- tibble(gene= from$gene,cat_from  = from$category,
                cat_to= to$category)
# 构建点文件
nodes <- bind_rows(
  transmute(edges, node_id = paste(gene, cat_from,sep = "|"),
            gene = gene, category = cat_from),
  transmute(edges, node_id = paste(gene, cat_to,sep = "|"),
            gene = gene, category = cat_to)) %>% distinct() %>% 
  mutate(category = 
           factor(category,levels = c("defense.response.to.Gram.positive.bacterium",
                     "innate.immune.response","proteolysis",
                     "positive.regulation.of.autophagy"))) %>%
  arrange(category,gene) %>%
  mutate(order = row_number()) %>%
  add_count(gene, name = "n_cat")
  
edges2 <- edges %>%
  transmute(from = paste(gene, cat_from, sep = "|"),
            to   = paste(gene, cat_to,   sep = "|"))
# 整合数据
g <- graph_from_data_frame(d = edges2,
  vertices = nodes %>% 
    select(name = node_id, gene, category, order),
  directed = FALSE)

V(g)$n_cat <- nodes$n_cat # 构建布局
lay <- create_layout(g,layout = "linear", circular = TRUE)
# 网络图绘制
ggraph(lay) +
  geom_edge_link(colour = "grey72",show.legend = FALSE)  +
  geom_node_point(aes(color = category,size = n_cat),
                  show.legend = FALSE) +
  geom_node_text(data = lay %>% filter(name !="TRIM38|innate.immune.response"),
                 aes(label=gene,x=x*1.05,y=y*1.05,
                     angle=-((-node_angle(x,y)+90) %% 180) + 90,
                     vjust=0.5,hjust=ifelse(x>0,0,1)),size=3) +
  geom_node_text(data = lay %>% filter(name =="TRIM38|innate.immune.response"),
                 aes(label=gene,x=x*1.05,y=y*1.05,
                     angle=-((-node_angle(x,y)+90) %% 180) + 90,
                     vjust=0.5,hjust=1),size=3) +
  scale_color_manual(values = c("#66a61e","#6f42c1","#f0ad4e","#20c997")) +
  scale_size_continuous(range = c(2,6)) + 
  coord_cartesian(clip="off") +
  theme_void() +
  theme(plot.margin = margin(2,2,2,2,unit="cm"))