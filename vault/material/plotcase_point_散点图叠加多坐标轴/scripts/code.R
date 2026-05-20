library(tidyverse)
library(readxl)
library(ggnewscale)
library(ggrepel)

sessionInfo()

df1 <- read_excel("41591_2025_3891_MOESM5_ESM.xlsx", sheet = 2) 
df2 <- read_excel("41591_2025_3891_MOESM5_ESM.xlsx", sheet = 3) 

ggplot() +
  geom_point(data=df1, aes(x=PC1_comb, y=PC2_comb,color=APOE4_anno_cat), size=1) +
  scale_color_manual(values = c("tan","tan3","tan4"))+
  guides(color=guide_legend(
    position = "inside",
    override.aes = list(size=5,shape=19,alpha=0.6))) +
  labs(color=bquote(italic('APOE4')), x="Genetic PC1", y="Genetic PC2") +
  new_scale_colour() +
  scale_y_continuous(limits = c(-0.06,0.06),
                     breaks = seq(-0.06,0.06,by=0.03),
                     labels = c(-0.06,-0.03,0,0.03,0.06),
                     sec.axis = sec_axis(
                       trans =~. /(0.06/0.121),
                       breaks = seq(-0.10,0.10,by=0.05),
                       labels = c(-0.10,-0.05,0,0.05,0.10),                 
                       name="Correlation r with PC2")) +
  scale_x_continuous(limits = c(-0.06,0.06),
                     breaks = seq(-0.06,0.06,by=0.03),
                     labels = c(-0.06,-0.03,0,0.03,0.06),
                     sec.axis = sec_axis(
                       trans =~. /(0.06/0.121),
                       breaks = seq(-0.10,0.10,by=0.05),
                       labels = c(-0.10,-0.05,0,0.05,0.10),                 
                       name="Correlation r with PC1")) +
  geom_segment(data = df2,
               aes(x = 0, y = 0, xend = corr_pc1*(0.06/0.121), yend = corr_pc2*(0.06/0.121),
                   color = super_class_metabolon),
               arrow = arrow(length = unit(0.08, "inches")), size = 0.6, show_guide = FALSE)+
  geom_label_repel(
    data=df2,
    aes(x = corr_pc1*(0.06/0.121), y = corr_pc2*(0.06/0.121),
        label = anno_metabolite_name, color = super_class_metabolon),size = 3,
    box.padding = unit(0.35, "lines"),
    point.padding = unit(0.3, "lines"),show_guide = FALSE) +
  theme_test() +
  theme(legend.background = element_blank(),
        legend.key = element_blank(),
        legend.position.inside = c(0.13,0.13),
        axis.title.x = element_text(size=11),
        axis.title.y = element_text(size=11),
        axis.text.x = element_text(size=10),
        axis.text.y = element_text(size=10)) 
