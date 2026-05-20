library(tidyverse)
library(ggrepel)
library(ggprism)

df <- read_tsv("data.tsv") %>%
  mutate(chr  = as.character(cluster),
    type = if_else(avg_log2FC > 0, "UP_Highly", "Down_Highly"))

cluster_colors <- c("#3B9AB2","#78B7C5","#EBCC2A","#E1AF00",
                    "#F21A00","#C51B7D","#7F3B08",
                    "#B2ABD2","#ABDDA4","#FC8D62")

# cluster 因子顺序
df$cluster <- factor(df$cluster, levels = unique(df$cluster))
# 水平背景
bg_df <- tibble(
  cluster = levels(df$cluster),
  xmin = seq_along(levels(df$cluster)) - 0.48,
  xmax = seq_along(levels(df$cluster)) + 0.48,
  ymin = -0.5,
  ymax = 0.5)
# 垂直背景
bg_vertical <- df %>%
  group_by(cluster) %>%
  summarise(
    ymin = min(avg_log2FC, na.rm = TRUE) - 0.1,
    ymax = max(avg_log2FC, na.rm = TRUE) + 0.1,
    .groups = "drop") %>%
  mutate(
    xmin = seq_along(cluster) - 0.48,
    xmax = seq_along(cluster) + 0.48)

# 标注基因 按正负筛选每组取5个
label_df <- df %>%
  filter(p_val_adj < 0.05, abs(avg_log2FC) > 1) %>%
  group_by(chr) %>%
  group_modify(~ bind_rows(
    slice_max(.x, avg_log2FC, n = 5),
    slice_min(.x, avg_log2FC, n = 5))) %>%
  ungroup()

ggplot(df, aes(cluster, avg_log2FC, color = type)) +
  # 绘制垂直背景条带
  geom_rect(data = bg_vertical,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
            inherit.aes = FALSE, fill = "grey95") +
  # 绘制分组条带
  geom_rect(data = bg_df,
            aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
                fill = cluster),
            inherit.aes = FALSE) +
  geom_jitter(stroke = 0) +
  # 添加基因标签
  geom_text_repel(data = label_df,
    aes(cluster, avg_log2FC, label = gene),
    size = 2.5, color = "black", box.padding = 0.2) +
  # 添加分组标签
  geom_text(aes(cluster,0,label = chr),
            size = 3, color = "white", show.legend = FALSE) +
  scale_fill_manual(values = cluster_colors, guide = "none") +
  scale_color_manual(values = c("#0073C2FF", "#EE0000FF")) +
  # 自定义刻度条
  scale_y_continuous(
    limits = c(-3, 7),
    breaks = c(-3, -2, -1, 0, 2, 4, 6),
    guide = "prism_offset_minor") +
  labs(x = NULL, y = "average log2FC") +
  # 设置图例属性
  guides(color = guide_legend(
    override.aes = list(size = 5, shape = 19))) +
  theme_prism(base_line_size = 0.3) +
  theme(
    panel.background = element_blank(),
    axis.text.x  = element_blank(),
    axis.ticks.x = element_blank(),
    axis.line.x  = element_blank(),
    axis.text.y  = element_text(size = 10),
    axis.title   = element_text(size = 11),
    legend.position = c(0.08, 0.9),
    legend.key = element_blank(),
    legend.background = element_blank(),
    legend.text = element_text(margin = margin(l = 0)))