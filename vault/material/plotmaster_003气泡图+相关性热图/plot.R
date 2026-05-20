library(ggplot2)

data_main <- read.csv("data_main.csv", check.names = FALSE)

data_main$p_value_bin <- factor(
  data_main$p_value_bin,
  levels = c("<0.0001", "<0.001", "<0.01", "<0.05", ">0.05")
)

p <- ggplot(data_main, aes(gene, group)) +
  geom_point(
    aes(fill = p_value_bin, size = abs_correlation),
    color = "#999999",
    shape = 21
  ) +
  scale_fill_manual(values = c("#212c5f", "#3366b1", "#42b0e4", "#7bc6ed", "#dfe1e0")) +
  geom_point(
    data = subset(data_main, direction == "positive"),
    aes(color = p_value_bin, size = abs_correlation),
    shape = 16
  ) +
  scale_color_manual(values = c("#f26666", "#f49699", "#facccc", "#facccc", "#d9dbd9")) +
  guides(
    size = guide_legend(title = "abs(correlation)"),
    fill = guide_legend(title = "Negative\np-value"),
    color = guide_legend(title = "Positive\np-value")
  ) +
  labs(x = NULL, y = NULL) +
  theme_bw() +
  theme(
    panel.grid.minor.x = element_blank(),
    panel.grid.major.x = element_blank(),
    axis.text.x = element_text(angle = 45, hjust = 1),
    legend.margin = margin(20, unit = "pt")
  )

dir.create("outputs", showWarnings = FALSE)
ggsave("outputs/rebuilt.png", p, height = 6, width = 12, dpi = 180)
