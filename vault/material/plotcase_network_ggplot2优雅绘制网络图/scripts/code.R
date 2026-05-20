library(tidyverse)

sessionInfo()

raw_data <- read_tsv("data.tsv", show_col_types = FALSE)
n_points <- nrow(raw_data)

if (n_points < 2) {
  stop("data.tsv must contain at least 2 rows.")
}

theta <- seq(0, 2 * pi, length.out = n_points + 1)[-1]

plot_data <- raw_data %>%
  mutate(
    theta = theta,
    x = 10 * cos(theta),
    y = 10 * sin(theta),
    labx = 12 * cos(theta),
    laby = 12 * sin(theta),
    angle = theta * 180 / pi,
    text_angle = if_else(angle > 90 & angle < 270, angle + 180, angle),
    text_hjust = if_else(angle > 90 & angle < 270, 1, 0))

creativity <- plot_data %>%
  filter(category == "Creativity") %>%
  select(x, y) %>%
  mutate(id = row_number())

creativity_edges <- crossing(id1 = creativity$id, id2 = creativity$id) %>%
  filter(id1 < id2) %>%
  inner_join(creativity, by = c("id1" = "id")) %>%
  inner_join(creativity, by = c("id2" = "id")) %>%
  transmute(x = x.x, y = y.x, xend = x.y, yend = y.y)

palette <- c(
  All = "white",
  Creativity = "#884c94",
  Identity = "#26aa83",
  Knowledge = "#4a75b0",
  Leadership = "#ff3377")

ggplot() +
  geom_segment(
    data = creativity_edges,
    mapping = aes(x = x, y = y, xend = xend, yend = yend),
    colour = alpha("#884c94", 0.5),
    linewidth = 0.05) +
  geom_point(
    data = plot_data,
    mapping = aes(x = x, y = y, colour = category),
    size = 2) +
  geom_text(
    data = plot_data,
    mapping = aes(x = labx,y = laby,
      label = name,angle = text_angle,hjust = text_hjust,
      colour = category),size = 3) +
  scale_colour_manual("", values = palette) +
  coord_equal(xlim = c(-20, 20), ylim = c(-20, 20), clip = "off") +
  labs(subtitle = "Creativity") +
  theme_void() +
  theme(
    legend.position = "none",
    plot.subtitle = element_text(hjust = 0.5, size = 18, color = "black"),
    plot.background = element_rect(fill = "white", colour = "white"),
    panel.background = element_rect(fill = "white", colour = "white"),
    plot.margin = unit(c(0, 0, 0, 0), "cm"))


