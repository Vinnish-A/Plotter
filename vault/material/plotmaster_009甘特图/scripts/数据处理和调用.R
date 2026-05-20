################# 甘特图代码开发 #####################
library(ggplot2)
library(grib)
library(tidyverse)

data <- read.csv("test.csv", fileEncoding = "UTF-8-BOM")

head(data)
#   CancerType  low high means  group number
# 1   Prostate 0.80 0.95 0.875 group1    217
# 2   Prostate 0.60 0.80 0.700 group2     77
# 3   Prostate 0.45 0.70 0.575 group3     19
# 4   Prostate 0.25 0.80 0.525 group4      7
# 5   Prostate 0.27 0.50 0.385 group5     38
# 6       Lung 0.55 0.72 0.635 group1    952

sample_data = paste(data$CancerType, data$group, sep = "_")

for (i in 1:length(sample_data)) {
  assign(sample_data[i], data.frame("CancerType" = rep(str_split(sample_data[i], "_", simplify = T)[1], data$number[i]),
                                    "Group" = rep(str_split(sample_data[i], "_", simplify = T)[2], data$number[i]),
                                    "Values" = runif(data$number[i], data$low[i], data$high[i])))
}

data2 <- data.frame()

for (i in 1:length(sample_data)) {
  data2 <- rbind(data2, get(sample_data[i]))
}

write.csv(data2, "data_raw.csv")

#################### 绘图 #################
# 对组内数据，根据means从大到小重排：
# data2 <- data %>% 
#   arrange(CancerType, means) %>% 
#   ungroup %>%
#   mutate(id=rep(c(1:5),4))


ggplot(data2, aes(x = CancerType, y = Values)) + 
  geom_gantt(aes(fill = Group), color = "black", 
             point_size = 2, 
             stroke = 0.1,
             position = position_dodge(width = 0.3), 
             width = 0.2)+
  coord_flip()

ggsave("Geom_gantt.pdf", height = 7, width = 10)


