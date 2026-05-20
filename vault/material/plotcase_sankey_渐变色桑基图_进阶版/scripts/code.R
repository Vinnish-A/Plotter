library(tidyverse)
library(grid)
library(ggsankeyfier)
library(ggnewscale)

sessionInfo()

raw_df <- read_tsv("F5d.tsv", show_col_types = FALSE) %>%
  select(where(~ !all(is.na(.x)))) %>%
  filter(!is.na(p), !is.na(group)) %>%
  mutate(across(where(is.character), str_squish))

function_cols <- names(raw_df)[4:ncol(raw_df)]

long_df <- raw_df %>%
  pivot_longer(
    all_of(function_cols),
    names_to = "Function_raw",
    values_to = "value"
  ) %>%
  mutate(
    value = parse_number(as.character(value)),
    Group = recode(
      group,
      Conser_Amb = "Conservation\nambient",
      Conser_Warm = "Conservation\nwarming",
      Conven_Amb = "Conventional\nambient",
      Conven_Warm = "Conventional\nwarming"
    ),
    Phylum = p %>%
      str_remove("^p__") %>%
      recode(
        Actinomycetota = "Actinobacteria",
        Pseudomonadota = "Proteobacteria",
        Desulfobacterota_B = "Desulfobacterota"
      ),
    Function = case_when(
      str_detect(Function_raw, "Ammonia oxidation") ~ "Ammonia oxidation",
      str_detect(Function_raw, "Nitrite oxidation") ~ "Nitrite oxidation",
      str_detect(Function_raw, "Nitrate reduction") ~ "Nitrate reduction",
      str_detect(Function_raw, "Nitrite reduction") ~ "Nitrite reduction",
      str_detect(Function_raw, "Nitric oxide reduction") ~ "Nitric oxide reduction",
      str_detect(Function_raw, "Nitrite ammonification") ~ "Nitrite ammonification",
      TRUE ~ Function_raw
    )
  ) %>%
  filter(!is.na(value), value > 0)

group_levels <- rev(c(
  "Conservation\nambient",
  "Conservation\nwarming",
  "Conventional\nambient",
  "Conventional\nwarming"
))

phylum_levels <- rev(c(
  "Thermoproteota",
  "Actinobacteria",
  "Nitrospirota",
  "Desulfobacterota",
  "Proteobacteria",
  "Bacillota",
  "Methylomirabilota",
  "Gemmatimonadota",
  "Chloroflexota",
  "Bacteroidota"
))

function_levels <- rev(c(
  "Ammonia oxidation",
  "Nitrite oxidation",
  "Nitrate reduction",
  "Nitrite ammonification",
  "Nitrite reduction",
  "Nitric oxide reduction"
))

long_df <- long_df %>%
  mutate(
    Group = factor(Group, levels = group_levels),
    Phylum = factor(Phylum, levels = phylum_levels),
    Function = factor(Function, levels = function_levels)
  )

node_cols <- c(
  "Conservation\nambient" = "#F2B94D",
  "Conservation\nwarming" = "#66C7DD",
  "Conventional\nambient" = "#F04C50",
  "Conventional\nwarming" = "#3CB878",
  "Thermoproteota" = "#D8DE2B",
  "Actinobacteria" = "#B72FA2",
  "Nitrospirota" = "#5BC2A8",
  "Desulfobacterota" = "#E77E45",
  "Proteobacteria" = "#6750A4",
  "Bacillota" = "#CDD4E8",
  "Methylomirabilota" = "#D78ED2",
  "Gemmatimonadota" = "#DCC7EA",
  "Chloroflexota" = "#B8863A",
  "Bacteroidota" = "#222222",
  "Ammonia oxidation" = "#63B6CB",
  "Nitrite oxidation" = "#B9D94E",
  "Nitrate reduction" = "#4DBBAE",
  "Nitrite ammonification" = "#B7C0E3",
  "Nitrite reduction" = "#C49A3A",
  "Nitric oxide reduction" = "#A23A83"
)

add_alpha <- function(hex, alpha = "99") {
  paste0(str_remove(hex, "#"), alpha) %>%
    paste0("#", .)
}

gradient_between <- function(from, to) {
  linearGradient(
    colours = c(add_alpha(node_cols[[as.character(from)]]), add_alpha(node_cols[[as.character(to)]])),
    stops = c(0, 1), x1 = 0, y1 = 0.5,
    x2 = 1, y2 = 0.5, group = FALSE
  )
}

df1_wide <- long_df %>%
  group_by(Group, Phylum) %>%
  summarise(n = sum(value), .groups = "drop") %>%
  filter(n > 0) %>%
  arrange(Group, Phylum) %>%
  mutate(patterns1 = map2(Group, Phylum, gradient_between))

df1 <- df1_wide %>%
  pivot_stages_longer(stages_from = c("Group", "Phylum"), values_from = "n")

patterns1 <- df1_wide$patterns1[df1$edge_id]

df2_wide <- long_df %>%
  group_by(Phylum, Function) %>%
  summarise(n = sum(value), .groups = "drop") %>%
  filter(n > 0) %>%
  arrange(Phylum, Function) %>%
  mutate(patterns2 = map2(Phylum, Function, gradient_between))

df2 <- df2_wide %>%
  pivot_stages_longer(stages_from = c("Phylum", "Function"), values_from = "n")

patterns2 <- df2_wide$patterns2[df2$edge_id]

pos <- position_sankey(width = 0.055, order = "as_is", v_space = "auto")

ggplot(
  data = df1,
  aes(
    x = stage,
    y = n,
    group = node,
    edge_id = edge_id,
    connector = connector
  )
) +
  geom_sankeynode(aes(fill = node), position = pos, color = "#222222", linewidth = 0.7) +
  scale_fill_manual(values = node_cols) +
  new_scale_fill() +
  geom_sankeyedge(aes(fill = patterns1), position = pos) +
  new_scale_fill() +
  geom_text(
    data = df1 %>% filter(stage == "Group"),
    aes(label = node),
    stat = "sankeynode",
    position = position_sankey(v_space = "auto", order = "as_is", nudge_x = 0.045),
    hjust = 0,
    size = 4.0,
    lineheight = 0.9
  ) +
  geom_sankeyedge(
    data = df2,
    aes(fill = patterns2),
    position = pos
  ) +
  new_scale_fill() +
  geom_sankeynode(
    data = df2 %>% filter(stage == "Function"),
    aes(fill = node),
    position = pos,
    color = "#222222",
    linewidth = 0.7) +
  scale_fill_manual(values = node_cols) +
  geom_text(
    data = df1 %>% filter(stage == "Phylum"),
    aes(label = node),
    stat = "sankeynode",
    position = position_sankey(v_space = "auto", order = "as_is", nudge_x = 0.055),
    hjust = 0,
    size = 3.5
  ) +
  geom_text(
    data = df2 %>% filter(stage == "Function"),
    aes(label = node),
    stat = "sankeynode",
    position = position_sankey(v_space = "auto", order = "as_is", nudge_x = -0.06),
    hjust = 1,
    size = 3.5
  ) +
  coord_cartesian(clip = "off") +
  scale_x_discrete(expand = expansion(add = c(0.18, 0.30))) +
  theme_void(base_size = 13) +
  theme(
    legend.position = "none")

