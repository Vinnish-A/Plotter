library(tidyverse)
library(ggh4x)

sessionInfo()

df <- read_tsv("data.tsv", show_col_types = FALSE) |>
  filter(!is.na(diameter), !is.na(antibiotic), !is.na(treatment)) |>
  mutate(
    diameter = as.numeric(diameter),
    treatment = factor(treatment, c("Control", "Warming")))


panel_info <- df |>
  distinct(antibiotic, drug_class) |>
  mutate(
    panel = row_number(),
    facet_label = factor(as.character(panel), levels = as.character(panel)))

df <- df |> left_join(panel_info, by = c("antibiotic", "drug_class"))

counts <- df |> count(facet_label, treatment, name = "n")

x_levels <- c(
  paste0("a_", unique(counts$n[counts$treatment == "Control"])),
  paste0("b_", unique(counts$n[counts$treatment == "Warming"]))
)

df <- df |>
  left_join(counts, by = c("facet_label", "treatment")) |>
  mutate(
    x_lab = factor(
      paste0(if_else(treatment == "Control", "a_", "b_"), n),
      levels = x_levels))

wilcox_df <- df |>
  group_by(antibiotic, drug_class, panel, facet_label) |>
  summarise(
    p = wilcox.test(diameter ~ treatment, alternative = "two.sided")$p.value,
    control_med = median(diameter[treatment == "Control"]),
    warming_med = median(diameter[treatment == "Warming"]),
    .groups = "drop"
  ) |>
  mutate(
    stars = case_when(p < 0.001 ~ "***", p < 0.01 ~ "**", p < 0.05 ~ "*", TRUE ~ ""),
    p_text = case_when(
      p < 1e-4 ~ str_replace(formatC(p, format = "e", digits = 1), "e", " × 10^"),
      p < 0.001 ~ str_remove(formatC(p, format = "f", digits = 5), "0+$"),
      TRUE ~ as.character(signif(p, 2))),
    p_label = if_else(stars == "", "", paste(stars, p_text, sep = "\n")),
    label_color = if_else(warming_med > control_med, "#1f78b4", "#e68613"))

yr <- df |>
  group_by(facet_label) |>
  summarise(ymin = min(diameter), ymax = max(diameter), span = ymax - ymin, .groups = "drop") |>
  mutate(
    span = if_else(span == 0, ymax * 0.08 + 1, span),
    p_y = ymax + 0.10 * span)

p_labs <- wilcox_df |> filter(p_label != "") |> 
  left_join(yr, by = "facet_label")

strip_fills <- panel_info |>
  mutate(fill = case_when(
    drug_class == "Aminoglycoside" ~ "#c7d7e8",
    drug_class == "Beta-lactam" ~ "#f6d2b3",
    drug_class == "Glycopeptide" ~ "#dddddd",
    drug_class == "Rifamycin" ~ "#f3cfae",
    drug_class == "Tertracycline" ~ "#dddddd",
    TRUE ~ "#dddddd")) |> pull(fill)

ggplot(df, aes(x_lab, diameter, color = treatment, fill = treatment)) +
  geom_violin(trim = FALSE, width = 0.92, linewidth = 0.7, alpha = 0.22) +
  geom_jitter(width = 0.16, size = 1.6, alpha = 0.18, stroke = 0) +
  geom_boxplot(width = 0.22, outlier.shape = NA, alpha = 0.55, linewidth = 0.45) +
  geom_text(
    data = p_labs,
    aes(x = 1.17, y = p_y, label = p_label),
    inherit.aes = FALSE,
    color = p_labs$label_color,
    lineheight = 0.82,
    size = 2.9,
    hjust = 0) +
  scale_color_manual(values = c(Control = "#169a96", Warming = "#9b007a")) +
  scale_fill_manual(values = c(Control = "#58b8b2", Warming = "#c85bb6")) +
  facet_wrap2(
    ~ facet_label,
    ncol = 7,
    scales = "free",
    strip = strip_themed(
      background_x = elem_list_rect(fill = strip_fills,color = NA))) +
  scale_x_discrete(labels = \(x) str_remove(x, "^[ab]_")) +
  scale_y_continuous(expand = expansion(mult = c(0.18, 0.14))) +
  coord_cartesian(clip = "off") +
  labs(x = NULL, y = "Diameter of inhibition zone (mm)") +
  theme_classic() +
  theme(
    legend.position = "none",
    panel.border = element_rect(color = "#3a3a3a", fill = NA, linewidth = 0.55),
    strip.text = element_text(size = 10, color = "#2c2c2c"),
    strip.background = element_rect(linewidth = 0.4),
    axis.text.x = element_text(color = "black", size = 9),
    axis.ticks.x = element_blank(),
    axis.text.y = element_text(color = "black", size = 8.5),
    axis.title.y = element_text(size = 12),
    plot.margin = margin(8, 8, 8, 8))

