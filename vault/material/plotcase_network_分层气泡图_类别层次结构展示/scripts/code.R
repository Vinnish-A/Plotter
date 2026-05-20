library(ggraph)
library(igraph)
library(tidyverse)

sessionInfo()

top_gene_labels <- 10
top_class_labels <- 10
max_genes_per_class <- 25

class_palette <- c(
  "Glycopeptide" = "#5B8CCB",
  "Rifamycin" = "#F47C20",
  "Aminoglycoside" = "#B37A32",
  "Beta-lactam" = "#7ECBD3",
  "Tetracycline" = "#D43F3A",
  "MLS" = "#8C8C8C",
  "Peptide" = "#7A7A7A",
  "Multidrug" = "#222222",
  "Phosphonic acid" = "#A36A2A",
  "Diaminopyrimidine" = "#222222",
  "Fluoroquinolone" = "#444444",
  "Phenicol" = "#444444"
)

clean_gene_label <- function(x) {
  case_when(
    str_detect(x, regex("vanR.*vanO", ignore_case = TRUE)) ~ "vanRO",
    str_detect(x, regex("vanW.*vanI", ignore_case = TRUE)) ~ "vanWI",
    str_detect(x, regex("vanS.*vanO", ignore_case = TRUE)) ~ "vanSO",
    str_detect(x, regex("rpoB mutants", ignore_case = TRUE)) ~ "rpoB",
    str_detect(x, regex("rox", ignore_case = TRUE)) ~ "rox",
    str_detect(x, regex("AAC\\(3\\).*IIb", ignore_case = TRUE)) ~ "AAC(3)\n-IIb",
    TRUE ~ x) |>
    str_replace_all(" gene in .* cluster", "") |>
    str_replace_all("Streptomyces venezuelae ", "") |>
    str_trunc(width = 18, side = "right")
}

raw_dt <- read_tsv("data.tsv") |>
  transmute(
    drug_class = str_replace_all(as.character(drug_class), "\\.", "-"),
    gene_name = as.character(gene_name),
    abundance = as.numeric(abundance)) |>
  filter(!is.na(drug_class), !is.na(gene_name), !is.na(abundance), abundance > 0) |>
  arrange(desc(abundance)) |>
  mutate(
    gene_label = clean_gene_label(gene_name),
    gene_rank = row_number())

dt <- raw_dt |>
  arrange(drug_class, desc(abundance)) |>
  mutate(class_gene_rank = row_number(), .by = drug_class) |>
  mutate(
    is_other = class_gene_rank > max_genes_per_class,
    gene_name = if_else(is_other, paste("Other", drug_class), gene_name),
    gene_label = if_else(is_other, NA_character_, gene_label),
    gene_rank = if_else(is_other, NA_integer_, gene_rank)) |>
  summarise(
    abundance = sum(abundance),
    gene_label = first(gene_label[!is.na(gene_label)], default = NA_character_),
    gene_rank = suppressWarnings(min(gene_rank, na.rm = TRUE)),
    .by = c(drug_class, gene_name)) |>
  mutate(
    gene_label = if_else(is.infinite(gene_rank), NA_character_, gene_label),
    gene_rank = as.integer(if_else(is.infinite(gene_rank), NA_real_, gene_rank))) |>
  arrange(desc(abundance)) |>
  mutate(gene_id = make.unique(paste(drug_class, gene_name, sep = "__"), sep = "__"))

class_summary <- dt |>
  summarise(total_abundance = sum(abundance), .by = drug_class) |>
  arrange(desc(total_abundance)) |>
  mutate(class_rank = row_number())

root_node <- tibble(
  name = "ARG",
  drug_class = NA_character_,
  abundance = sum(dt$abundance),
  gene_label = NA_character_,
  gene_rank = NA_integer_,
  class_rank = NA_integer_,
  total_abundance = sum(dt$abundance),
  node_type = "root")

class_nodes <- class_summary |>
  transmute(name = drug_class,
    drug_class,
    abundance = total_abundance,
    gene_label = NA_character_,
    gene_rank = NA_integer_,
    class_rank,
    total_abundance,
    node_type = "class")

gene_nodes <- dt |> left_join(class_summary, by = "drug_class") |>
  transmute(
    name = gene_id,
    drug_class,
    abundance,
    gene_label,
    gene_rank,
    class_rank,
    total_abundance,
    node_type = "gene")

vertices <- bind_rows(root_node, class_nodes, gene_nodes)

edges <- bind_rows(
  tibble(from = "ARG", to = class_summary$drug_class),
  transmute(dt, from = drug_class, to = gene_id))

graph <- graph_from_data_frame(edges, vertices = vertices)
layout <- create_layout(graph, layout = "circlepack", weight = abundance) |>
  mutate(
    label_gene = if_else(node_type == "gene" & gene_rank <= top_gene_labels, gene_label, NA_character_),
    label_class = if_else(node_type == "class" & class_rank <= top_class_labels, drug_class, NA_character_),
    label_angle = atan2(y, x),
    label_x = x + cos(label_angle) * (r + 0.025),
    label_y = y + sin(label_angle) * (r + 0.025),
    label_hjust = if_else(label_x >= 0, 0, 1))

plot_limit <- max(abs(c(layout$x - layout$r, layout$x + layout$r,
                        layout$y - layout$r, layout$y + layout$r))) * 1.08

ggraph(layout) +
  geom_node_circle(
    aes(filter = node_type == "class", color = drug_class),
    fill = NA,
    linewidth = 0.7,
    alpha = 0.95) +
  geom_node_circle(
    aes(filter = node_type == "gene", fill = drug_class),
    color = "#8A8A8A",
    linewidth = 0.25,
    alpha = 0.98) +
  geom_node_text(
    aes(label = label_gene, filter = !is.na(label_gene)),
    color = "#111111",
    size = 3.5,
    lineheight = 0.9,
    fontface = "italic") +
  geom_text(
    data = filter(layout, !is.na(label_class)),
    aes(x = label_x, y = label_y, label = label_class, color = drug_class, hjust = label_hjust),
    inherit.aes = FALSE,
    size = 3.9,
    fontface = "plain",
    check_overlap = TRUE) +
  scale_fill_manual(values = class_palette, na.value = "#D9D9D9") +
  scale_color_manual(values = class_palette, na.value = "#666666") +
  coord_equal(xlim = c(-plot_limit, plot_limit), ylim = c(-plot_limit, plot_limit), clip = "off") +
  theme_void(base_size = 14) +
  theme(
    legend.position = "none",
    plot.margin = margin(24, 36, 24, 36),
    plot.background = element_rect(fill = "white", color = NA))
