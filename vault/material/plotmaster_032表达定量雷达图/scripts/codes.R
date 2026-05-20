library(ggradar)
library(readxl)
library(ggplot2)
library(tidyverse)
library(scales)

data <- read_excel("radar.eg.xlsx")
group <- read_excel("radar_groups.eg.xlsx")

data$`log2(fc)` <- as.numeric(data$`log2(fc)`)
data$col <- ifelse(data$`log2(fc)` >= 0, "#c6dc5d", "#efcb41")
data$angle <- -seq(0, 360, 360/nrow(data))[-1]

data_radar <- as.data.frame(t(data[,c(2:4)]))
colnames(data_radar) <- data$id 
data_radar$group <- rownames(data_radar)
data_radar <- data_radar[,c(20,1:19)] %>% 
  mutate_at(vars(-group), function(x) rescale(x, to = c(0.5, 0.75)))

data$CSH3_rescale <- as.numeric(data_radar[1,-1])
data$CSK3_rescale <- as.numeric(data_radar[2,-1])

ggplot(data)+
  # 灰色线段：
  geom_linerange(aes(id, ymin = 5.5, ymax = 7), color = "#b3b6b7", linewidth = 0.3) +

  # 外圈散点和数值注释：
  geom_point(aes(id, 7, size = abs(round(`log2(fc)`)), color = col)) +
  geom_text(aes(id, 8, label = round(`log2(fc)`, 2), 
            angle = angle), size = 2, 
            color = "#b3b6b7") +
  
  # 中间数值注释：
  geom_text(aes(id, 5, label = round(CSH3, 2), 
                angle = angle), size = 2, 
            color = "#e6c2ed") +
  geom_text(aes(id, 4.5, label = round(CSK3, 2), 
                angle = angle), size = 2, 
            color = "#c6cafb") +
  
  # 内圈背景：
  geom_ribbon(aes(seq(0.5, nrow(data)+0.5, length.out = nrow(data)), 
                  ymin = 2, ymax = 3.5), fill = "#f1f4f3") +
  geom_hline(yintercept = seq(2.5, 3.5, 0.5), color = "#b3b6b7", linewidth = 0.3)+
  geom_linerange(aes(id, ymin = 2, ymax = 4), color = "#b3b6b7", linewidth = 0.3) +
  
  # 雷达图：不好做！
  # geom_ribbon(aes(seq(0.5, nrow(data)+0.5, length.out = nrow(data)),
  #                 ymin = 2, ymax = 2 + CSH3_rescale),
  #             fill = "#de9fe7", alpha = 0.8)+
  # geom_ribbon(aes(seq(0.5, nrow(data)+0.5, length.out = nrow(data)),
  #                 ymin = 2, ymax = 2 + CSK3_rescale),
  #             fill = "#c2c3fb", alpha = 0.8)+
  
  scale_color_manual(values = unique(data$col)) +
  scale_size_continuous(range = c(2,8))+
  ylim(0, 8) +
  xlab("") +
  ylab("") +
  theme_minimal()+
  theme(axis.text.x = element_blank(), 
        axis.text.y = element_blank(), 
        panel.grid = element_blank(),
        legend.position = "none")+
  coord_polar()

ggsave("p1.pdf", height = 5, width = 5)

# 雷达图：
ggradar(data_radar[1:2,], fill = T, 
        group.colours = c("#de9fe7", "#c2c3fb"),
        # 去掉散点和描边：
        group.point.size = 0, group.line.width = 0,
        # 去掉标签：
        label.gridline.min = F,
        label.gridline.mid = F,
        label.gridline.max = F,
        axis.label.size = 0, axis.line.colour = NA,
        gridline.min.colour = NA,
        gridline.mid.colour = NA,
        gridline.max.colour = NA,
        # 去掉背景色：
        background.circle.colour = NA,
        plot.legend = F)

ggsave("p2.pdf", height = 2, width = 2)
