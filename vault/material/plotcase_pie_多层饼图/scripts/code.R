library(tidyverse)
library(ggtext) 

# 读取数据
data <- read_tsv("data.tsv")  
group <- read_tsv("group.tsv")  

# 处理 `data.tsv` 数据（外环）
data <- data %>%
  mutate(Proportion = as.numeric(gsub("%", "", Proportion))) %>%
  group_by(Habitat) %>%
  mutate(ymax = cumsum(Proportion), ymin = lag(ymax, default = 0))

# 处理 `group.tsv` 数据（内环）
group <- group %>%
  mutate(`Proportion of lysogen` = as.numeric(gsub("%", "", `Proportion of lysogen`)),
         `Proportion of nonlysogen` = as.numeric(gsub("%", "", `Proportion of nonlysogen`))) %>%
  pivot_longer(cols = c(`Proportion of lysogen`, `Proportion of nonlysogen`),
               names_to = "Type", values_to = "Proportion") %>%
  group_by(Habitat) %>%
  mutate(ymax = cumsum(Proportion), ymin = lag(ymax, default = 0))

# 自定义颜色
phylum_colors <- c(
  "Actinomycetota" = "#F3C300", "Bacillota" = "#875692",
  "Bacteroidota" = "#F38400",
  "Chlamydiota" = "#A1CAF1", "Cyanobacteriota" = "#BE0032", 
  "Deinococcota" = "#C2B078",
  "Mycoplasmatota" = "#848482", "Others" = "#008856",
  "Planctomycetota" = "#E68FAC",
  "Pseudomonadota" = "#0067A5", "Spirochaetota" = "#F99379",
  "Verrucomicrobiota" = "#604E97")

type_colors <- c("Proportion of lysogen" = "#E69F00",
                 "Proportion of nonlysogen" = "#A6A6D2")

# 绘制嵌套环形图
ggplot() +
  # 内环（溶源菌 vs. 非溶源菌）
  geom_rect(data = group, aes(ymax = ymax, ymin = ymin,
                              xmax = 1.5, xmin = 1, fill = Type),
            color = "white", size = 0.3) +
  # 外环（微生物门分类）
  geom_rect(data = data, aes(ymax = ymax, ymin = ymin,
                             xmax = 2, xmin = 1.5, fill = Phylum),
            color = "white", size = 0.3) +
  # 样本信息（文本标签）
  geom_text(data = group %>% distinct(Habitat, `Number of genome`), 
            aes(x = 0, y = 50, label = paste0(Habitat, "\n", `Number of genome`)), 
            size = 3, fontface = "bold") +
  # 颜色映射
  scale_fill_manual(values = c(type_colors, phylum_colors)) +
  # 极坐标转换
  coord_polar(theta = "y") +
  # 分面显示不同的 `Habitat`
  facet_wrap(~Habitat, nrow = 3) +
  # 主题设置
  theme_void() +
  theme(
    legend.position = "right",
    strip.text = element_blank(),
    panel.spacing = unit(1, "lines")) +
  # 图例标题
  guides(fill = guide_legend(title = NULL))

