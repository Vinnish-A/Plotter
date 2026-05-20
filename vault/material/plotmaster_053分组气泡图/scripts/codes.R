########### 数据构建 --------------
library(tidyverse)

data <- as.data.frame(matrix(NA, nrow = 15, ncol = 13))

for (i in 1:13) {
  if (i < 10) {
    data[,i] <- c(runif(7, min = -2, max = -0.5),
                  runif(8, min = 0.5, max = 2.1))
  } else {
    data[,i] <- c(runif(7, min = -2, max = -0.5),
                  runif(8, min = 0.5, max = 4))
  }
}

colnames(data) <- c("TG", "Sphingolipid", "PUFA", "PS", "PHA",
                    "PG", "PE", "PC", "HBMP", "DAG", "BMP",
                    "Acyl-AA", "ACAR")

# 宽转长：
data_long <- pivot_longer(data,
                          cols = everything(),
                          names_to = "Class", values_to = "Log2FC")
data_long$Pvalue <- runif(nrow(data_long), 1e-08, 1e-02)

write.csv(data_long, "data.csv")

############## 绘图 -----------------
library(ggplot2)

# 绘图：
ggplot(data_long)+
  # 散点：
  geom_point(aes(Log2FC, Class,
                 size = -log10(Pvalue), fill = Class),
             shape = 21, alpha = 0.6)+
  # 垂直虚线：
  geom_vline(xintercept = 0, linetype = "dashed", color = "grey")+
  xlim(-2, 4) +
  # 主题调整：
  theme_bw()+
  theme(panel.grid = element_blank(),
        legend.position = c(0.98, 0.98),
        legend.justification = c(1, 1),
        text = element_text(face = "bold"))+
  guides(fill = "none")

ggsave("plot.pdf", height = 3.5, width = 7)






