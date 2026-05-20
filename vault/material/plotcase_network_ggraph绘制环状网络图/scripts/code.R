library(tidyverse)
library(tidygraph)
library(ggraph)
library(geomtextpath)

sessionInfo()

category_palette <- c(Knowledge = "#5686C3",Leadership = "#973CB6",
                      Creativity = "#F5A300",Identity = "#75C500")

df <- readr::read_csv("data.csv", show_col_types = FALSE) %>%
  mutate(across(
    where(is.character),
    ~ stringr::str_squish(stringr::str_replace_all(.x, "\u2019", "'"))))

category_color <- tibble(
  category = names(category_palette),
  color = unname(category_palette))

category_order <- df %>% filter(category != "All") %>%
  distinct(category) %>%
  pull(category)

people <- df %>%
  filter(category != "All", name != "Unsung hero") %>%
  left_join(category_color, by = "category")

df_nodes <- people %>%
  select(name, category, country, color)

nodes <- tibble(
  node = c("root", category_order, people$name),
  level = c(1, rep(2, length(category_order)), rep(3, nrow(people))))

edges <- bind_rows(
  tibble(category = category_order) %>%
    left_join(category_color, by = "category") %>%
    transmute(from = "root", to = category, color),
  people %>%
    transmute(from = category, to = name, color))

graph <- tbl_graph(nodes = nodes,edges = edges,
  directed = TRUE,node_key = "node")

portraits <- create_layout(graph, layout = "dendrogram", circular = TRUE) %>%
  left_join(df_nodes, by = c("node" = "name")) %>%
  left_join(category_color, by = c("node" = "category"), suffix = c("", "_category")) %>%
  mutate(
    color = coalesce(color, color_category, "#D9D9D9"),
    label_angle = -(((-node_angle(x, y) + 90) %% 180) - 90),
    label_hjust = if_else(between(node_angle(x, y), 90, 270), 1, 0)) %>%
  select(-color_category)

outer_text <- portraits %>% filter(level == 3) %>%
  mutate(radius = sqrt(x^2 + y^2),
    label_x = 1.05 * x,
    label_y = 1.05 * y,
    radial_x = x / radius,
    radial_y = y / radius,
    path_len = 0.013 * pmax(nchar(node), 10)) %>%
  tidyr::uncount(2, .id = "path_id") %>%
  mutate(path_step = path_id - 1,
    x = label_x + path_step * path_len * radial_x,
    y = label_y + path_step * path_len * radial_y)

ggraph(portraits) +
  geom_edge_diagonal(aes(colour = color), width = 1, alpha = 0.85) +
  geom_node_point(
    data = filter(portraits, level == 3),
    aes(x = x, y = y, colour = color),size = 3) +
  geom_node_text(data = filter(portraits, level == 2),
    aes(x = 0.75 * x,y = 0.75 * y,
      label = toupper(node),colour = color,
      hjust = c(1, 1, 0.8, -0.1),
      vjust = c(0, 0, 0, 0)),
    fontface = "bold",size = 4) +
  geom_textpath(data = outer_text,
    aes(x = x,y = y,label = node,colour = color,
      group = node,vjust=0.5,hjust=0),
    text_only = TRUE,upright = TRUE,halign = "left",
    lineend = "round",remove_long = FALSE,size = 3) +
  scale_edge_colour_identity() +
  scale_colour_identity() +
  coord_equal(clip = "off") +
  labs(x = NULL, y = NULL) +
  theme_void() +
  theme(legend.position = "none",
    plot.margin = unit(c(2.5, 0.2, 2.5, 0.2), "cm"))

