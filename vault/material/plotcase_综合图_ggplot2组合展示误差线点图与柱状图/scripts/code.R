library(tidyverse)
library(patchwork)
library(legendry)

sessionInfo()

type_cols <- c(
  lignin = "#D55E00",
  litter = "#009E73",
  SOC = "#9A6324",
  fieldlignin = "black"
)

type_labs <- c(
  lignin = "Lignin",
  litter = "Litter",
  SOC = "SOC",
  fieldlignin = "Field lignin"
)

group_sections <- tribble(
  ~section,       ~group,
  "Geochemical",  "pH",
  "Geochemical",  "Silt+Clay",
  "Geochemical",  "Alox",
  "Geochemical",  "Feox",
  "Geochemical",  "Fecd-ox",
  "Geochemical",  "FeHCl",
  "Geochemical",  "Mncd",
  "Geochemical",  "Cacd",
  "Microbial",    "Fungal composition",
  "Microbial",    "Fungal Chao1",
  "Microbial",    "Fungal quantity",
  "Microbial",    "Bacterial quantity",
  "Microbial",    "Fungal-to-bacterial ratio",
  "N-related",    "Bulk N",
  "N-related",    "Bulk C/N",
  "Climatic",     "MAT",
  "Climatic",     "MAP"
)

group_levels <- rev(group_sections$group)
section_key <- group_sections %>%
  group_by(section) %>%
  summarise(
    start = first(group),
    end = last(group),
    .groups = "drop"
  ) %>%
  mutate(section = factor(section, levels = unique(group_sections$section)))

df <- read_tsv("data.tsv", show_col_types = FALSE) %>%
  left_join(group_sections, by = "group") %>%
  mutate(
    group = factor(group, levels = group_levels),
    type = factor(type, levels = names(type_cols))
  )

base_theme <- theme_bw(base_size = 9) +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(colour = "grey80", linewidth = 0.4),
    panel.grid.major.x = element_line(colour = "grey92", linewidth = 0.3),
    axis.text = element_text(colour = "grey25", face = "bold"),
    axis.title = element_text(colour = "black", face = "bold"),
    plot.background = element_blank(),
    panel.background = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(colour = "black", size = 8),
    legend.key = element_blank(),
    legend.background = element_blank()
  )

p_point <- df %>%
  filter(!is.na(mean), !is.na(error)) %>%
  ggplot(aes(mean, group, colour = type)) +
  geom_vline(xintercept = 0, linetype = 2, colour = "grey55", linewidth = 0.4) +
  geom_errorbar(
    aes(xmin = mean - error, xmax = mean + error),
    width = 0.18,
    linewidth = 0.7,
    position = position_dodge(width = 0.65)
  ) +
  geom_point(
    size = 2.6,
    position = position_dodge(width = 0.65)
  ) +
  scale_y_discrete(
    limits = group_levels,
    labels = c(
      "Fungal composition" = "Fungal PC2",
      "Fungal-to-bacterial ratio" = "F/B",
      "Bulk N" = "Total N",
      "Bulk C/N" = "C/N",
      "Alox" = expression(Al[ox]),
      "Feox" = expression(Fe[ox]),
      "Fecd-ox" = expression(Fe[cd - ox]),
      "FeHCl" = expression(Fe[HCl]),
      "Mncd" = expression(Mn[cd]),
      "Cacd" = expression(Ca[cd])
    ),
    guide = guide_axis_nested(
      key = key_range_map(section_key, start = start, end = end, name = section),
      title = NULL,
      position = "left",
      pad_discrete = 0.1
    )
  ) +
  scale_x_continuous(limits = c(-1, 0.75), breaks = seq(-1, 0.5, 0.5)) +
  scale_colour_manual(values = type_cols, labels = type_labs, drop = FALSE) +
  labs(x = "Standardized coefficient in LMM", y = NULL) +
  base_theme +
  theme_guide(bracket = element_line(
    colour = "black",linetype=2,linewidth = 0.6)) +
  theme(
    legend.position = c(0.24, 0.24),
    legend.justification = c(0, 0),
    axis.text.y.left = element_text(
      colour = "grey25",
      face = "bold",
      size = 9),
    plot.margin = margin(5.5, 4, 5.5, 5.5))

p_bar <- df %>%
  filter(!is.na(`IncMSE (%)`)) %>%
  ggplot(aes(`IncMSE (%)`, group, fill = type)) +
  geom_col(
    width = 0.68,
    position = position_dodge(width = 0.72)
  ) +
  scale_y_discrete(
    limits = group_levels,
    labels = NULL
  ) +
  scale_x_continuous(
    limits = c(0, 30),
    breaks = seq(0, 30, 10),
    expand = expansion(mult = c(0, 0.02))
  ) +
  scale_fill_manual(values = type_cols, labels = type_labs, drop = FALSE) +
  labs(x = "%IncMSE in RFM", y = NULL) +
  base_theme +
  theme(
    axis.text.y = element_blank(),
    axis.ticks.y = element_blank(),
    legend.position = "none",
    plot.margin = margin(5.5, 5.5, 5.5, 4)
  )

p_point + p_bar + plot_layout(widths = c(1.16, 1))

