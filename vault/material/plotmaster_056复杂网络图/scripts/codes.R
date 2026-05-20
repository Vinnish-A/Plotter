library(readxl)
library(tidyverse)
library(ggplot2)

########## 载入数据 -----------------
# 只需要获取代谢物及其对应的Class（Subpathway）
data1 <- read_excel("Supplemental Excel Table.xlsx", sheet = 6, skip = 1)[,c(2, 8)] %>%
  unique()

# 获取绘图数据：
data2 <- read_excel("Supplemental Excel Table.xlsx", sheet = 11, skip = 1)[, c(1,2,4)]
data2 <- data2[-nrow(data2), ]
# 使用fill函数填充第1、4列：
data2 <- data2 %>% fill(Pollutant) %>% fill(Outcome)

# 合并数据：
data <- merge(data1, data2, by.x = "Serum metabolite", by.y = "Metabolite")

# 似乎作者对数据进行了一定的筛选，师兄这里就随机挑选120行作图：
set.seed(123)
data <- data[sample(1:nrow(data), 120), ]

# 统计代谢物及其分类出现的次数，以确定散点的大小：
metabolite_count <- as.data.frame(table(data$`Serum metabolite`))
Polutant_count <- as.data.frame(table(data$Pollutant))
Outcome_count <- as.data.frame(table(data$Outcome))

# 给每个散点赋予一个坐标轴位置：
metabolite_count$x[1:nrow(metabolite_count)] <- 1:nrow(metabolite_count)
metabolite_count$y[1:nrow(metabolite_count)] <- 0
# 这个数字根据后面的图形自行修改：
Polutant_count$x[1:nrow(Polutant_count)] <- c(10, 20, 1, 80)
Polutant_count$y[1:nrow(Polutant_count)] <- 5
# 这个数字根据后面的图形自行修改：
Outcome_count$x[1:nrow(Outcome_count)] <- c(30, 45, 70)
Outcome_count$y[1:nrow(Outcome_count)] <- -5

# 合并数据：
data_count <- rbind(rbind(metabolite_count, Polutant_count), Outcome_count)
colnames(data_count)[1] <- "Serum metabolite"
# 加入分组信息 -- 到这绘制散点的数据算是完成了！
data_count <- left_join(data_count, data[,1:2], by = "Serum metabolite")

data_count$`Super pathway`[c(121:124)] <- "OPEs"
data_count$`Super pathway`[c(125:127)] <- data_count$`Serum metabolite`[c(125:127)]

########## 先绘制散点 ----------------
colors <- c("#476b71", "#8697a0", "#2da3d1", "#806766",
            "#55bfe2", "#b2bec5", "#d2b698")
names(colors) <- unique(data_count$`Super pathway`)[1:7]
colors <- c(colors, "OPEs" = "#1999a9", "GSP" = "#efc000",
            "HOMA-IR" = "#9a8419", "FPG" = "#1981c8")

p <- ggplot(data_count)+
  geom_point(aes(x, y, size = Freq, color = `Super pathway`))+
  geom_text(data = data_count[1:120,],
            aes(x, y-0.1, label = `Serum metabolite`, color = `Super pathway`),
            angle = 90, hjust = 1, vjust = 0.5, size = 1.5, show.legend = F)+
  geom_text(data = data_count[121:124,],
            aes(x+3, y, label = `Serum metabolite`, color = `Super pathway`),
            angle = 0, hjust = 0, size = 4, show.legend = F)+
  geom_text(data = data_count[125:127,],
            aes(x, y-0.5, label = `Serum metabolite`, color = `Super pathway`),
            angle = 0, hjust = 0.5, vjust = 0.5, size = 4, show.legend = F)+
  scale_color_manual(name = "Class", values = colors)+
  theme_void()

p

########### 折线的数据 ---------------
data_line <- data[, c(1,3)]
data_line[121:(120*2),] <- data[, c(1,4)]
data_line$group <- paste0("group", 1:nrow(data_line))
data_line <- pivot_longer(data_line, cols = -group,
                          names_to = "Class", values_to = "Serum metabolite")

data_line <- left_join(data_line, unique(data_count[,c(1,3,4)]), by = "Serum metabolite")

p+geom_line(data = data_line, aes(x, y, group = group, color = "#b7bfcb"),
            linewidth = 0.2, alpha = 0.3, show.legend = F)

ggsave("plot.pdf", height = 5, width = 10)














