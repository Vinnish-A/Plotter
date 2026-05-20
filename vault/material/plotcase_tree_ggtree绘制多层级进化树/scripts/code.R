library(tidyverse)
library(vegan)
library(ape)
library(ggtree)
library(ggtreeExtra)
library(ggnewscale)
library(ggstar)

read_region <- function(count_file, group_file, region) {
  group <- read.delim(group_file, check.names = FALSE) %>%
    transmute(label = paste0(sample, ".", .env$region), sample, habitat, park,
              region = .env$region)

  domain <- read.delim(count_file, row.names = 1, check.names = FALSE) %>%
    mutate(D = replace_na(D, "Unidentified")) %>%
    group_by(D) %>%
    summarise(across(all_of(group$sample), sum), .groups = "drop") %>%
    column_to_rownames("D") %>%
    rename_with(~ paste0(.x, ".", region))

  list(domain = domain, group = group)
}

v4 <- read_region("v4.txt", "group.v4.txt", "v4")
v9 <- read_region("v9.txt", "group.v9.txt", "v9")

domain <- full_join(
  rownames_to_column(v4$domain, "domain"),
  rownames_to_column(v9$domain, "domain"),
  by = "domain"
) %>%
  column_to_rownames("domain") %>%
  mutate(across(everything(), ~ replace_na(.x, 0)))

sample_group <- bind_rows(v4$group, v9$group)

tree <- hclust(vegdist(t(domain), method = "bray"), method = "ward.D2") %>%
  as.phylo() %>%
  groupOTU(split(sample_group$label, sample_group$habitat))

habitat_col <- c("#339933", "#990000", "#CC9900", "#663366", "#99CCFF")
region_col <- c(v4 = "#9ac9db", v9 = "#f8ac8c")
park_col <- c("#8ECFC9", "#FFBE7A", "#FA7F6F", "#82B0D2", "#BEB8DC", "#E7DAD2")

(ggtree(tree, layout = "fan", ladderize = TRUE, size = 0.5,
        branch.length = "none", aes(color = group)) %<+% sample_group) +
  scale_color_manual(values = habitat_col) +
  theme(legend.position = "right") +
  new_scale_colour() +
  geom_tippoint(aes(colour = region), size = 3, stroke = 0, alpha = 1) +
  scale_colour_manual(
    name = "Region",
    values = region_col,
    guide = guide_legend(keywidth = 0.3, keyheight = 0.3, ncol = 1,
                         override.aes = list(size = 2, alpha = 1), order = 1)) +
  new_scale_colour() +
  geom_fruit(
    geom = geom_star,
    mapping = aes(fill = park),
    starshape = 1,
    colour = NA,
    size = 2,
    starstroke = 0,
    pwidth = 0.1,
    offset = 0.08) +
  scale_fill_manual(
    name = "Park",
    values = park_col,
    guide = guide_legend(keywidth = 0.3, keyheight = 0.3, order = 3),
    na.translate = FALSE) +
  theme(
    legend.title = element_text(size = 10),
    legend.text = element_text(size = 10),
    legend.spacing.x = unit(0.1, "cm"),
    legend.spacing.y = unit(0.3, "cm"))
