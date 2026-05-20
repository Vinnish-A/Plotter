library(tidyverse)
library(readxl)
library(ggalluvial)
library(RColorBrewer)
library(scales)

sessionInfo()
# 数据清洗
df <- read_excel("NCOMMS-24-29043C_Source Data to Main Figures.xlsx",
                 sheet = "Fig.1a",skip = 1) %>% 
  rename(family = `Viral Taxonomy (family)`) %>%
  mutate(row_sum = rowSums(across(-family))) %>% 
  mutate(family = factor(family, levels = family[order(row_sum)])) %>% 
  select(-row_sum) %>% 
  pivot_longer(-family)
# 绘制冲积图
df %>% ggplot(.,aes(name,value,alluvium=family,stratum=family)) +
  geom_alluvium(aes(fill=family,color=family)) +
  geom_stratum(aes(fill=family,color=family)) +
  scale_fill_brewer(palette = "Paired") +
  scale_color_brewer(palette = "Paired")+
  scale_x_discrete(expand = c(0,0)) +
  scale_y_continuous(expand = c(0,0),
                     labels = percent_format(accuracy = 1)) +
  labs(y="Relative abundance (%)",x=NULL) +
  theme_test()+
  theme(legend.background = element_blank(),
        legend.title = element_blank(),
        legend.key.height = unit(0.4,"cm"),
        legend.key.width = unit(0.6,"cm"),
        legend.key.spacing.y = unit(0.1,"cm"),
        axis.text=element_text(color="black",size=11))