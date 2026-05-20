library(tidyverse)
library(lme4)
library(car)

data_path <- "F1_f.tsv"

group_info <- tibble::tribble(
  ~raw_group, ~label, ~block,
  "antibiotic.target.alteration", "Antibiotic target alteration", "mechanism",
  "antibiotic.target.alteration/antibiotic.target.replacement", "Antibiotic target\nalteration or replacement", "mechanism",
  "antibiotic.inactivation", "Antibiotic inactivation", "mechanism",
  "Glycopeptide", "Glycopeptide", "drug",
  "Rifamycin", "Rifamycin", "drug",
  "Aminoglycoside", "Aminoglycoside", "drug",
  "Tetracycline", "Tetracycline", "drug",
  "Beta.lactam", "\\u03b2-Lactam", "drug"
) %>%
  mutate(
    label = str_replace_all(label, "\\\\u03b2", "\u03b2"),
    y = rev(seq_len(n())))

format_p_plot <- function(p) {
  if (p < 0.001) {
    exponent <- floor(log10(p))
    mantissa <- p / 10^exponent
    sprintf("%.1f %%*%% 10^%d", mantissa, exponent)
  } else {
    sprintf("%.2g", p)
  }
}

sig_label <- function(p) {
  case_when(
    p < 0.001 ~ "***",
    p < 0.01 ~ "**",
    p < 0.05 ~ "*",
    TRUE ~ ""
  )
}

df <- read_tsv(data_path, show_col_types = FALSE) %>%
  pivot_longer(-id, names_to = "raw_group", values_to = "abundance") %>%
  mutate(
    year = 2000 + as.integer(str_match(id, "^X([0-9]{2})_")[, 2]),
    plot_id = str_match(id, "^X[0-9]+_([0-9]+)[A-Z]$")[, 2],
    warming = if_else(year >= 2010 & plot_id %in% c("1", "10", "16", "20"), 1L, 0L)
  ) %>%
  inner_join(group_info, by = "raw_group")

model_results <- df %>%
  group_by(raw_group, label, block, y) %>%
  group_modify(\(.x, .y) {
    model_df <- .x %>%
      mutate(rescaled_abundance = as.numeric(scale(abundance)))

    fit <- lmer(rescaled_abundance ~ warming + (1 | year), data = model_df, REML = FALSE)
    wald_table <- car::Anova(fit, type = "II", test.statistic = "Chisq")
    coefs <- summary(fit)$coefficients

    tibble(
      effect = unname(coefs["warming", "Estimate"]),
      sem = unname(coefs["warming", "Std. Error"]),
      chisq = unname(wald_table["warming", "Chisq"]),
      p_value = unname(wald_table["warming", "Pr(>Chisq)"])
    )
  }) %>%
  ungroup() %>%
  mutate(
    xmin = effect - sem,
    xmax = effect + sem,
    p_label = vapply(p_value, format_p_plot, character(1)),
    stars = sig_label(p_value),
    point_color = if_else(p_value < 0.05, "#9A007E", "#777777"),
    star_side = if_else(stars != "" & xmax > 1.05, "left", "right"),
    star_x = if_else(star_side == "left", xmin - 0.14, xmax + 0.12),
    star_hjust = if_else(star_side == "left", 1, 0)
  ) %>%
  arrange(desc(y))

ggplot(model_results) +
  annotate(
    "rect",
    xmin = -0.5, xmax = 3.25, ymin = 5.5, ymax = 8.5,
    fill = "#E9F7F5",
    color = NA
  ) +
  annotate(
    "rect",
    xmin = -0.5, xmax = 3.25, ymin = 0.5, ymax = 5.5,
    fill = "#F8EAF8",
    color = NA
  ) +
  annotate(
    "rect",
    xmin = -0.5, xmax = 1.38, ymin = 0.5, ymax = 8.5,
    fill = NA,
    color = "#777777",
    linewidth = 0.65) +
  geom_errorbar(
    aes(y = y, xmin = xmin, xmax = xmax, color = point_color),
    orientation = "y",
    width = 0.22,
    linewidth = 1.0) +
  geom_point(
    aes(x = effect, y = y, color = point_color),
    shape = 21,
    fill = "white",
    size = 3.4,
    stroke = 1.2) +
  geom_text(aes(x = -0.62, y = y, label = p_label),
    parse = TRUE,hjust = 1,color = "black",size = 3.6) +
  geom_text(aes(x = 1.57, y = y, label = label),hjust = 0,
            color = "#333333",size = 3.8,lineheight = 0.9) +
  geom_text(
    aes(x = star_x, y = y, label = stars, hjust = star_hjust),color = "#9A007E",
    fontface = "bold",size = 4.1) +
  annotate("text",x = -1.38,y = 8.86,
    label = "italic(P)~values",parse = TRUE,hjust = 0,
    color = "black",size = 3.7) +
  annotate("text",x = 0.45,y = -0.35,label = "Effect size",size = 3.8) +
  scale_color_identity() +
  scale_x_continuous(
    limits = c(-1.82, 4.25),
    breaks = c(0, 0.5, 1.0),
    labels = c("0", "0.5", "1.0"),
    expand = expansion(mult = c(0, 0))) +
  scale_y_continuous(
    limits = c(-0.55, 9.1),
    breaks = NULL,
    expand = expansion(mult = c(0, 0))) +
  coord_cartesian(clip = "off") +
  theme(
    axis.title = element_blank(),
    axis.text.x = element_text(color = "black", size = 10,margin = margin(t=-1.5,unit="cm")),
    axis.text.y = element_blank(),
    axis.ticks.x = element_blank(),
    axis.ticks.y = element_blank(),
    axis.line.x = element_blank(),
    axis.line.y = element_blank(),
    legend.position = "none",
    panel.background = element_blank(),
    plot.margin = margin(0,0,2,0,unit="cm"))
