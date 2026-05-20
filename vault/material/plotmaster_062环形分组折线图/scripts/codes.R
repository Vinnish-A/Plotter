library(tidyverse)

set.seed(123)

# 数据构建；10小组每小组6个值，4种色彩对应4个大组
data <- data.frame(x = rep(paste0("N_", 1:60), 4),
                    y = round(c(runif(-1, 0, n = 60),
                          runif(0, 0.5, n = 60),
                          runif(0.5, 1, n = 60),
                          runif(1, 1.5, n = 60)), 2),
                   group1 = rep(rep(paste0("group", 1:10), each = 6), 4),
                    group2 = rep(paste0("Group", 1:4), each = 60))

# 对数据做转换
datagroup <- data$group1 %>% unique()

data_empty <- tibble('group1' = datagroup,
                     'x' = paste0('empty_x_', seq_along(datagroup)),
                     'y' = NA)

data_empty <- bind_rows(data_empty[1,], data_empty[1,], data_empty)

allplotdata <- data.frame()

for (i in 1:4) {
  data_Group <- data %>% filter(group2 == paste0("Group", i))
  data_empty$group2 <- paste0("Group", i)

  tmp_plotdata <- data_empty %>% bind_rows(data_empty) %>%
    bind_rows(data_Group) %>% arrange(group1) %>% mutate(xid = 1:n()) %>%
    mutate(angle = 90 - 360 * (xid - 0.5) / n()) %>%
    mutate(hjust = ifelse(angle < -90, 1, 0)) %>%
    mutate(angle = ifelse(angle < -90, angle+180, angle))

  allplotdata <- bind_rows(allplotdata, tmp_plotdata)
}

# 提取出空的数据，做一些调整
firstxid <- which(str_detect(allplotdata$x, pattern = "empty_x")) # 1 12 43 58
firstxid <- firstxid[seq(6, length(firstxid)/4, 2)]

# 自定义坐标轴的网格
griddata <- expand.grid('locationx' = c(1.7, 2, firstxid, firstxid-0.3),
                        'locationy' = coordy$coordylocation)

segment_data <- data.frame('from' = firstxid + 1,
                           'to' = c(c(firstxid - 1)[-1], nrow(tmp_plotdata)),
                           'label' = datagroup) %>%
  mutate(labelx = as.integer((from + to)/2)) %>%
  mutate(angle = 190 - 360 * (labelx - 0.5) / nrow(tmp_plotdata)) %>%
  mutate(angle = ifelse(angle > 90, angle+180, angle)) %>%
  mutate(angle = ifelse(angle < -90, angle+180, angle))

# 自定坐标轴
coordy <- tibble('coordylocation' = seq(-1.5, 1.5, 0.5),
                 'coordytext' = as.character(round(coordylocation, 1)),
                 'x' = 4)



################## 绘图 -----------------
ggplot() +
  # 内圈灰色阴影：
  geom_rect(aes(xmin = 0, xmax = nrow(tmp_plotdata),
                ymin = -5, ymax = -1.5),
            fill = "#fafafa") +
  # 最内圈标签：
  geom_text(data = segment_data,
            aes(x = labelx, label = label, angle = angle),
            # y值需要根据你的数据调整：
            y = -2, size = 2, fontface = "bold") +
  # 柱形：
  geom_point(data = allplotdata, size = 1,
           aes(x = xid, y = y, color = group2), stat = 'identity') +
  # 折线：
  geom_line(data = allplotdata, linewidth = 0.5,
             aes(x = xid, y = y, color = group2), stat = 'identity') +
  # 每个柱形的标签：
  geom_text(data = allplotdata %>%
              filter(!str_detect(x, pattern = "empty_x")),
            # y值需要根据你的数据调整：
            aes(x = xid, label = x, y = 1.7,
                angle = angle, hjust = hjust),
            color="black", size = 1.5) +
  # y轴刻度：
  geom_text(data = coordy, size = 1.5,
            aes(x = x, y = coordylocation, label = coordytext),
            color="black", size = 1.5 , angle = 0, fontface="bold") +
  # 最内圈黑色线：
  geom_segment(data = segment_data,
               aes(x = from, xend = to),
               y = -1.5, yend=-1.5) +
  # 0刻度黑色线：
  geom_segment(data = segment_data,
               aes(x = from, xend = to),
               y = 0, yend = 0) +
  # 网格线：
  geom_segment(data = griddata,
               aes(x = locationx-0.5, xend = locationx + 0.5,
                   y = locationy, yend = locationy),
               colour = "grey", size=0.6) +
  # 颜色：
  scale_color_manual(values = c("Group1" = "#0073b2",
                               "Group2" = "#d95c00",
                               "Group3" = "#e0a000",
                               "Group4" = "#cb7aa7"))+
  # 主题：
  scale_x_continuous(expand = c(0, 0)) +
  scale_y_continuous(limits = c(-5, 2)) +
  coord_polar(start = -2*pi/84*4
    ) +
  theme_void() +
  theme(legend.position = 'none')


# 保存：
ggsave("plot.pdf", height = 7, width = 7)





