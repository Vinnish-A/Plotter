library(tidyverse)
library(ggpubr)
library(rstatix)
library(ggprism)
library(ggtext)

df <- read_tsv("data.tsv") %>%
  rename(Expression = `Cell Count ×10^6`) %>% 
  mutate(Treatment = paste(Mice, Group, sep = " + "))
# 设置顺序（决定柱子顺序）
df$Treatment <- factor(df$Treatment,
  levels = c("Control + IgG","Control + ɑPD-1",
    "MdkDTR cKO + IgG","MdkDTR cKO + ɑPD-1"))

df$Celltype <- factor(df$Celltype,levels = unique(df$Celltype))

# 2. 统计分析（双侧非配对 t-test）
stat.test <- df %>%
  group_by(Celltype) %>%
  t_test(Expression ~ Treatment, var.equal = TRUE) %>%
  mutate(p.label = case_when(
    p < 0.0001 ~ "P < 0.0001",
    TRUE ~ paste0("P = ", signif(p,3)))) %>%
  add_xy_position(x = "Celltype",dodge = 0.8,step.increase = 0.12) %>% 
  filter(
    (group1 == "Control + IgG"      & group2 == "MdkDTR cKO + IgG") |
      (group1 == "Control + ɑPD-1"      & group2 == "MdkDTR cKO + ɑPD-1") |
      (group1 == "MdkDTR cKO + IgG"   & group2 == "MdkDTR cKO + ɑPD-1")) %>% 
  mutate(y.position=c(5,5.7,6.4,
                      3,3.7,4.4,
                      1,1.7,2.4,
                      1,1.7,2.4,
                      1,1.7,2.4))

ggplot(df, aes(Celltype, Expression, fill = Treatment)) +
  stat_summary(fun = mean,geom = "bar",
    width = 0.75,alpha=0.5,
    position = position_dodge(0.8)) +
  # mean_sd1 = mean ± 2 × SD，所以在通过一行代码定义mult = 1
  stat_summary(fun.data = mean_sdl,
    fun.args = list(mult = 1),
    geom = "errorbar",width = 0.25,
    position = position_dodge(0.8)) +
  # 添加抖动点
  geom_point(aes(color = Treatment),
    position = position_jitterdodge(jitter.width = 0.2,
      dodge.width = 0.8),size = 3,alpha = 0.5,show.legend = FALSE) +
  # 显著性
  stat_pvalue_manual(stat.test,label = "p.label",hide.ns = TRUE,
    tip.length = 0,size = 3.5,color="black") +
  scale_fill_manual(values = c(
    "Control + IgG" = "#4C9BE8",
    "Control + ɑPD-1" = "#F8766D",
    "MdkDTR cKO + IgG" = "#F1A340",
    "MdkDTR cKO + ɑPD-1" = "#1B9E77")) +
  scale_color_manual(values = c(
    "Control + IgG" = "#4C9BE8",
    "Control + ɑPD-1" = "#F8766D",
    "MdkDTR cKO + IgG" = "#F1A340",
    "MdkDTR cKO + ɑPD-1" = "#1B9E77")) +
  scale_y_continuous(expand = expansion(mult = c(0,0.1)),
    name = "Absolute count in tumour <br> (10 <sup>6</sup> cells per g)") +
  labs(x = NULL) +
  theme_classic() +
  theme(
    legend.title = element_blank(),
    legend.position = c(0.83,0.85),
    legend.text = element_text(color="black"),
    axis.title.y.left = element_markdown(face="bold"),
    axis.text.x = element_text(face = "bold"),
    panel.grid = element_blank())

