library(tidyverse)
library(ggforce)
#devtools::install_github("Hy4m/linkET", force = TRUE)
library(linkET)
library(RColorBrewer)

sessionInfo()

geom_arg_couple <- function(data, mapping = NULL, node_order, label_x,
                            anchor_x = -3.15, anchor_y = 2.95,
                            curvature = NULL, ..., show.legend = NA) {
  stopifnot("env" %in% names(data))
  n <- length(node_order)
  d <- data |>
    mutate(
      .idx = match(env, node_order),
      .x = anchor_x,
      .y = anchor_y,
      .xend = label_x[.idx] - 0.44,
      .yend = n - .idx + 1,
      .curvature = case_when(
        .idx <= 3 ~ -0.70,
        .idx <= 6 ~ -0.42,
        .idx <= 11 ~ -0.22,
        TRUE ~ 0.08))
  if (!is.null(curvature)) {
    d$.curvature <- curvature
  }
  base_mapping <- aes(x = .x, y = .y, xend = .xend, yend = .yend, group = env,
                      curvature = .curvature)
  if (!is.null(mapping)) {
    base_mapping[names(mapping)] <- mapping
  }
  linkET:::geom_curve2(
    data = d,
    mapping = base_mapping,
    inherit.aes = FALSE,
    lineend = "butt",
    node.shape = NA,
    show.legend = show.legend,
    ...
  )
}

input_xlsx <- "41586_2026_10413_MOESM7_ESM.xlsx"
raw <- read_excel(input_xlsx, sheet = "a", col_names = FALSE)

order_raw <- c(
  "temperature_annual", "NO3.N", "C3 biomass", "F_B_metagenome",
  "P_B_metagenome", "NH4.N", "TN", "plant.richness",
  "plant biomass", "TC", "pH", "Bacteria_plfa", "C4 biomass",
  "F_B_ratio_plfa", "annual_moisture", "Fungi_plfa"
)

labels_plain <- c(
  "Temperature", "NO3-N", "C3 biomass", "F/B_metaG", "P/B_metaG",
  "NH4-N", "TN", "Plant richness", "Total plant biomass", "TC", "pH",
  "Bacterial PLFA", "C4 biomass", "F/B_PLFA", "Moisture", "Fungal PLFA"
)

labels_parse <- c(
  "'Temperature'", "NO[3]*'-N'", "C[3]*' biomass'", "'F/B_metaG'",
  "'P/B_metaG'", "NH[4]*'-N'", "'TN'", "'Plant richness'",
  "'Total plant biomass'", "'TC'", "'pH'", "'Bacterial PLFA'",
  "C[4]*' biomass'", "'F/B_PLFA'", "'Moisture'", "'Fungal PLFA'")

n <- length(order_raw)

lmm <- raw[3:18, 1:3] |>
  setNames(c("env", "lmm_r", "p_adj")) |>
  mutate(
    env = as.character(env),
    lmm_r = as.numeric(lmm_r),
    p_adj = as.numeric(p_adj),
    idx = match(env, order_raw),
    label = labels_plain[idx],
    y_diag = n - idx + 1,
    x_label = idx - 0.40,
    sign = factor(if_else(lmm_r >= 0, "Positive", "Negative"),
                  levels = c("Positive", "Negative")),
    p_class = if_else(p_adj < 0.05, "P < 0.05", "P >= 0.05"),
    r_class = cut(abs(lmm_r), breaks = c(-Inf, 0.25, 0.35, Inf),
                  labels = c("<0.25", "0.25-0.35", "0.35-0.45")),
    line_width = case_when(
      r_class == "0.35-0.45" ~ 1.65,
      r_class == "0.25-0.35" ~ 1.05,
      TRUE ~ 0.55),
    p_label = if_else(p_adj < 0.05, formatC(p_adj, format = "f", digits = 4), ""))

cor_mat <- raw[3:18, 7:23]
colnames(cor_mat) <- c("env", raw[2, 8:23] |> unlist(use.names = FALSE) |> as.character())

cor_long <- cor_mat |>
  mutate(env = as.character(env)) |>
  filter(env %in% order_raw) |>
  arrange(match(env, order_raw)) |>
  pivot_longer(-env, names_to = "env2", values_to = "r") |>
  mutate(
    r = as.numeric(r),
    i = match(env, order_raw),
    j = match(env2, order_raw),
    x = j,
    y = n - i + 1,
    side = 0.11 + 0.72 * abs(r),
    xmin = x - side / 2,
    xmax = x + side / 2,
    ymin = y - side / 2,
    ymax = y + side / 2) |>
  filter(j > i)

grid_df <- expand.grid(i = seq_len(n), j = seq_len(n)) |>
  as_tibble() |> filter(j > i) |>
  mutate(x = j, y = n - i + 1)

diag_labels <- tibble(idx = seq_len(n),
  x = seq_len(n) - 0.26,y = n - seq_len(n) + 1,
  label = labels_parse)

top_labels <- tibble(idx = seq_len(n),
  x = seq_len(n),y = n + 2.12,label = labels_parse)

importance <- tibble(x = seq_len(n),y = n + 1.32,
  value = c(3.84, 1.01, 0.93, 0.91, 0.90, 0.80, 0.41, 0.39,
            0.26, 0.16, -0.05, -0.31, -0.41, -0.42, -0.48, -0.68),
  label = if_else(abs(value) >= 1,
                  formatC(value, format = "f", digits = 2),
                  sub("0$", "", formatC(value, format = "f", digits = 2))))

anchor_x <- -3.15
anchor_y <- 2.95

make_curve <- function(row) {
  idx <- row$idx
  end_x <- row$x_label - 0.44
  end_y <- row$y_diag
  
  if (idx <= 3) {
    ctrl_x <- anchor_x - 2.65 + 0.55 * idx
    ctrl_y <- (anchor_y + end_y) / 2 + 3.8 - 0.45 * idx
  } else if (idx <= 6) {
    ctrl_x <- anchor_x - 1.05 + 0.42 * idx
    ctrl_y <- (anchor_y + end_y) / 2 + 1.0
  } else if (idx <= 11) {
    ctrl_x <- (anchor_x + end_x) / 2 - 0.25
    ctrl_y <- (anchor_y + end_y) / 2 + 0.55
  } else {
    ctrl_x <- (anchor_x + end_x) / 2 + 0.25
    ctrl_y <- (anchor_y + end_y) / 2 - 0.15
  }
  
  tibble(group = row$env,
    x = c(anchor_x, ctrl_x, end_x),
    y = c(anchor_y, ctrl_y, end_y),
    sign = row$sign,
    p_class = row$p_class,
    line_width = row$line_width,
    r_class = row$r_class)
}

curve_df <- bind_rows(lapply(seq_len(nrow(lmm)), function(k) make_curve(lmm[k, ])))
p_text <- lmm |> filter(p_label != "") |>
  mutate(x = case_when(
      env == "temperature_annual" ~ -5.45,
      env == "NO3.N" ~ -3.95,
      env == "C3 biomass" ~ -3.20,
      env == "NH4.N" ~ -0.82),
    y = case_when(
      env == "temperature_annual" ~ 13.95,
      env == "NO3.N" ~ 13.08,
      env == "C3 biomass" ~ 12.10,
      env == "NH4.N" ~ 8.55),angle = 52)

blue <- "#0072B2"
orange <- "#D95F02"
pearson_pal <- colorRampPalette(RColorBrewer::brewer.pal(11, "RdBu"))(256)
importance_pal <- colorRampPalette(c("#F7F4F6", "#D6B9D1", "#7B247E"))(256)

ggplot() +
  geom_arg_couple(data = lmm,
    mapping = aes(colour = sign, size = r_class, linetype = p_class),
    node_order = order_raw,
    label_x = lmm$x_label[match(order_raw, lmm$env)],
    show.legend = TRUE) +
  scale_colour_manual(
    values = c("Positive" = blue, "Negative" = orange),
    name = "Correlation",
    guide = guide_legend(order = 1,ncol = 1,direction = "vertical",
                         title.position = "top")) +
  scale_size_manual(
    values = c("<0.25" = 0.55, "0.25-0.35" = 1.05, "0.35-0.45" = 1.65),
    name = "|LMM r|",
    guide = guide_legend(order = 2, ncol = 1, direction = "vertical",
                         title.position = "top")) +
  scale_linetype_manual(
    values = c("P >= 0.05" = "22", "P < 0.05" = "solid"),
    name = expression(italic(P)~values),
    guide = guide_legend(order = 3, ncol = 1, direction = "vertical",
                         title.position = "top",
                         override.aes = list(colour = "black",size = 0.9))) +
  ggnewscale::new_scale_colour() +
  geom_text(data = p_text,
    aes(x, y, label = p_label, angle = angle),size = 3) +
  geom_rect(data = grid_df,
    aes(xmin = x - 0.5, xmax = x + 0.5, ymin = y - 0.5, ymax = y + 0.5),
    fill = "white",colour = "#BDBDBD",linewidth = 0.5) +
  geom_rect(
    data = cor_long,
    aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax, fill = r),
    colour = NA,alpha = 0.98) +
  scale_fill_gradientn(colours = pearson_pal,limits = c(-1, 1),
    name = "Pearson's r",
    guide = guide_colorbar(order = 4,position = "right",
      title.position = "right",direction = "vertical",
      barheight = unit(8, "cm"),barwidth = unit(0.34, "cm"),
      theme = theme(legend.title = element_text(angle = 90, hjust = 0.5)))
    ) +
  ggnewscale::new_scale_fill() +
  geom_tile(data = importance,aes(x, y, fill = value),
    width = 1,height = 0.85,colour = "#4D4D4D",
    linewidth = 0.35) +
  geom_text(data = importance |> filter(abs(value) <= 2),
    aes(x, y, label = label),colour = "#222222",
    size = 2.5,show.legend = FALSE) +
  geom_text(
    data = importance |> filter(abs(value) > 2),aes(x, y, label = label),
    colour = "white",size = 2.5,show.legend = FALSE) +
  scale_fill_gradientn(colours = importance_pal, limits = c(-1, 4),
                       guide = "none") +
  geom_text(data = top_labels,aes(x, y, label = label),
    parse = TRUE,angle = 45,hjust = 0,vjust = 0.5,size = 3) +
  geom_label(data = diag_labels,aes(x, y, label = label),parse = TRUE,
    hjust = 1,vjust = 0.5,size = 3,fill = "white",linewidth = 0,
    label.padding = unit(0.03, "lines")) +
  annotate("text", x = anchor_x - 1.35, y = anchor_y - 1.15,
           label = "ARG\nabundance", hjust = 0, size = 3.5) +
  annotate("text", x = n + 0.85, y = n + 1.42, label = "Importance", hjust = 0, size = 3) +
  coord_fixed(xlim = c(-5.8, n + 1.72), ylim = c(0.35, n + 2.95), clip = "off") +
  theme_void() +
  theme(plot.margin = margin(1,0.5,0.5,0.5,unit="cm"),
    legend.position = "bottom",
    legend.direction = "vertical",
    legend.box = "horizontal",
    legend.box.just = "center",
    legend.spacing.x = unit(0.9, "cm"),
    legend.spacing.y = unit(0.05, "cm"),
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 10),
    legend.key.width = unit(0.85, "cm"),
    legend.key.height = unit(0.45, "cm"),
    plot.background = element_rect(fill = "white", colour = NA))

