library(tidyverse)
library(legendry)

df <- read_tsv("data.tsv")

dox_levels <- c("-", "+")
g1_levels <- c("EV", "Atf4-1", "Atf4-2")
g2_levels <- c("KP-Y", "KP-O")

df <- df %>%
  mutate(
    type = factor(type, levels = dox_levels),
    group1 = factor(group1, levels = g1_levels),
    group2 = factor(group2, levels = g2_levels))

x_leve<- crossing(group2 = g2_levels,group1 = g1_levels,
                     type = dox_levels) %>%
  transmute(x_id = str_c(type, group1, group2, sep = ".")) %>% 
  pull(x_id)

df <- df %>%
  mutate(x_id = factor(str_c(type, group1, group2, sep = "."),
                       levels = x_leve)) %>% 
  mutate(fill_key = str_c(group2, group1, sep = "."))

bar_pal <- c("KP-Y.EV" = "#2A9D9A","KP-Y.Atf4-1" = "#1E7F86",
             "KP-Y.Atf4-2" = "#145D66","KP-O.EV" = "#F0AD1E",
             "KP-O.Atf4-1" = "#C75A2D","KP-O.Atf4-2" = "#B54D28")

ggplot() +
  stat_summary(data=df,aes(x = x_id,y = Counts,fill = fill_key),
               fun = mean,geom = "bar",
               color = "#444444",linewidth = 0.5) +
  stat_summary(data=df,aes(x = x_id,y = Counts),
               fun.data = mean_se,
               fun.args = list(mult = 1), 
               geom = "errorbar",width = 0.2) +
  geom_point(data = df,aes(x = x_id,y = Counts,shape = group2,
      fill = fill_key),size = 3,color = "#333333",stroke = 0.8,
    position = position_jitter(width = 0.12, height = 0)) +
  scale_fill_manual(values = bar_pal, guide = "none") +
  scale_shape_manual(values = c("KP-Y" = 22, "KP-O" = 21),guide = "none") +
  scale_y_continuous(breaks = c(0, 20, 40, 60),
    expand = expansion(mult = c(0, 0.1))) +
  labs(y = "Lung metastasis burden (%)", x = NULL) +
  guides(x = guide_axis_nested(
      key = key_range_auto(sep = "\\."),
      drop_zero = FALSE,
      pad_discrete = 0.45,
      levels_text = list(
        element_text(size = 20,color="black"),   
        element_text(size = 14,margin = margin(t=0.1,b=0.3,unit="cm")),
        element_text(size = 11,color="white",face="bold",
                     margin = margin(t=-0.2,b=0,unit="cm"))),
      levels_brackets=list(
        element_line(
          color=c("#F0AD1E","#2A9D9A"),linewidth = 7),
        element_line(
          color=c("black"),linewidth = 0.8)))) +
  theme_classic() +
  theme(
    panel.background = element_blank(),
    plot.background = element_blank(),
    axis.ticks.length.x = unit(0.15, "cm"),
    axis.text.y = element_text(size = 14, color = "#202020"),
    axis.title.y = element_text(size = 15),
    plot.margin = margin(0.5,0.5,0.5,0.5,unit="cm")) 
