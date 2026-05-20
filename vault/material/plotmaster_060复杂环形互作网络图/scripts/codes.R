# 网络图1
library(tidyverse)
library(readxl)
library(igraph)
library(ggraph)
library(tidygraph)

set.seed(123)

# 读取数据：
df <- read_excel("Supplemental Excel Table.xlsx", sheet = 7, skip = 1)[,c(1:3, 5, 8)] %>%
  unique()
df <- df[-nrow(df), ]
colnames(df)[2] <- "Biomaker"

variable_info.sum <- df[,c(2, 5)]
colnames(variable_info.sum) <- c("var", "info")

# 使用fill函数填充第1、4列：
df <- df %>% fill(Pollutant)
table(edge_data$from)

# 随机在数据中选200行展示，否则数据太多；
df <- df[c(1:2, sample(3:nrow(df), 198)), ]

# FDR为零的值改成1*10^-6
df$FDR[which(df$FDR == 0)] <- 1e-6

edge_data = df[,c("Pollutant", "Biomaker", "Estimate", "FDR")] %>%
  dplyr::rename(from = Pollutant, to = Biomaker, Correlation = Estimate, p = FDR) %>%
  dplyr::mutate(fdr= -log10(p)) %>%
  dplyr::select(from, to, Correlation, fdr)

node_data <-
  edge_data %>%
  dplyr::select(from, to) %>%
  tidyr::pivot_longer(cols = c(from, to),
                      names_to = "Class",
                      values_to = "node") %>%
  dplyr::mutate(
    class1 = variable_info.sum$info[match(node,variable_info.sum$var)]
  ) %>%
  dplyr::select(node, class1) %>%
  dplyr::rename(Class = class1) %>%
  dplyr::distinct(node, .keep_all = TRUE) %>%
  dplyr::arrange(Class) %>%
  dplyr::mutate(true_name= node)

code_vec <- setNames(as.numeric(factor(node_data$node, levels = node_data$node)),
                     node_data$node)

edge_data2 <- data.frame(from = code_vec[edge_data$from],
                         to = code_vec[edge_data$to],
                         Correlation = edge_data$Correlation,
                         fdr = edge_data$fdr)

node_data$Class[is.na(node_data$Class)] <- "OPEs"

total_graph <-
  tidygraph::tbl_graph(nodes = node_data,
                       edges = edge_data2,
                       directed = TRUE) %>%
  dplyr::mutate(Degree = centrality_degree(mode = 'all'))

pal <- wesanderson::wes_palette(name = "Zissou1", n = 100, type = "continuous")
pal2 <- gplots::colorpanel(300, low = 'steelblue',
                           mid = "#F9F0D9",
                           high = 'coral4')

g <- total_graph

V(g)$type <- bipartite_mapping(g)$type

coords <-
  create_layout(g, layout = "bipartite") %>%
  dplyr::select(x, y)
coords$y[coords$y == 0] <- 0.3

coords <-
  coords %>%
  dplyr::select(x,y) %>%
  dplyr::mutate(theta = x / (max(x) + 1) * 2 * pi,
                r = y + 1,
                x = r * cos(theta),
                y = r * sin(theta))

my_graph <-
  create_layout(graph = g,
                layout = "manual",
                x = coords$x,
                y = coords$y
                # node.position = coords
  )

# 设置颜色模式, 如果想要一一对应，最好给颜色命名：
table(node_data$Class)
value.sum <- c("#436342", "#8f742f", "#d8995b",
               "#ad5657", "#c6a58d", "#e4c97d", "#66a9b3",
               "#62b2dc", "#765396", "#b5cf70")

plot <-
  ggraph(my_graph,
         layout = "bipartite") +
  geom_edge_link(aes(color = Correlation),
                 show.legend = TRUE) +
  geom_node_point(
    aes(fill = Class,
        color = Class,
        size = Degree),
    shape = 21,
    show.legend = TRUE
  )+
  scale_fill_manual(values = value.sum) +
  scale_color_manual(values = value.sum) +
  # scale_alpha_manual(values = alpha_value.sum) +
  geom_node_text(
    aes(
      x = x * 1.03,
      y = y * 1.03,
      label = ifelse(Class %in% c("OPEs"), true_name, true_name),
      hjust = ifelse(Class %in% c("OPEs"), 'inward', "outward"),
      angle = -((-node_angle(x, y) + 90) %% 180) + 90,
      size = ifelse(Class %in% c("OPEs"), 40, 4.5),
      # size = 1,
      colour = Class
    ),repel = FALSE,
    # size = 3,
    alpha = 1,
    show.legend = FALSE,
  ) +
  guides(
    edge_width = guide_legend(title = "-log10(BH adjusted P value)",
                              override.aes = list(shape = NA)),
    edge_color = ggraph::guide_edge_colorbar(title = "Effect"),
    fill = guide_legend(
      title = "Class",
      override.aes = list(size = 7, linetype = "blank")
    ),
    size = guide_legend(title = "Degree", override.aes = list(linetype = 0))
  ) +
  # ggraph::scale_edge_color_gradientn(colours = pal2, limits = c(-0.6,0.6)) +
  ggraph::scale_edge_color_gradientn(colours = colorRampPalette(c("#5ca995","#f8f1dd","#ca5737"))(30)) +
  ggraph::scale_edge_width(range = c(0.1, 1)) +
  scale_size_continuous(range = c(1.5, 15)) +
  theme_void() +
  theme(
    legend.position = "right",
    legend.title = element_text(size = 12),
    legend.text = element_text(size = 12),
    plot.background = element_rect(fill = "transparent", color = NA),
    panel.background = element_rect(fill = "transparent", color = NA)
  ) +
  expand_limits(x = c(-3.2, 3.2), y = c(-3.2, 3.2))

pdf("plot.pdf", height = 15, width = 17)
plot
dev.off()

