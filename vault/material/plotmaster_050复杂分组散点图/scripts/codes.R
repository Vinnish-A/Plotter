library(readxl)
library(ggplot2)
library(latex2exp)
library(tidyverse)
library(ggnewscale)
library(ggrepel)

# 读取数据：
data <- read_excel("total_w_unc.xlsx", sheet = 2)
data$`Tissue group` <- factor(data$`Tissue group`,
                              levels = c("Marrow", "Blood", "Lymphatic System",
                                         "Barrier Epithelial", "Internal Epithelial",
                                         "Connective", "Adipose Tissue", "Striated Muscle",
                                         "CNS"))

# 单独绘制散点图：
ggplot(data)+
  # 散点图
  geom_point(aes(log10(mass+0.01), log10(density+0.01),
                 shape = Method, fill = `Tissue group`),
             color = "black", size = 2)+
  # 这里主要是为了构建图例：
  geom_point(aes(log10(mass+0.01), log10(density+0.01),
                 color = `Tissue group`),
             size = 0)+
  # 形状：
  scale_shape_manual(values = c("Literature\n(histology + cytometry)" = 23,
                                "Multiplex" = 24, "Mostly extrapolation" = 21))+
  # 填充：
  scale_fill_manual(values = c("#800000", "#cd5d5c", "#9470dc", "#006400",
                               "#2e8a57", "#fed700", "#f5f5f5", "#deb887", "#c0c0c0"))+
  # 图例：
  scale_color_manual(name = "Tissue group",
                     values = c("#800000", "#cd5d5c", "#9470dc", "#006400",
                               "#2e8a57", "#fed700", "#f5f5f5", "#deb887", "#c0c0c0"))+
  # x轴和y轴的调整：
  scale_x_continuous(limits = c(0,5), breaks = 0:5,
                     labels = c(TeX("$10^{0}$"), TeX("$10^{1}$"), TeX("$10^{2}$"),
                                TeX("$10^{3}$"), TeX("$10^{4}$"), TeX("$10^{5}$")))+
  scale_y_continuous(limits = c(5,10), breaks = 5:10,
                     labels = c(TeX("$10^{5}$"), TeX("$10^{6}$"), TeX("$10^{7}$"),
                                TeX("$10^{8}$"), TeX("$10^{9}$"), TeX("$10^{10}$")))+
  xlab("Organ mass [g]")+
  ylab("Organ immune density [cells/g]")+
  # 删除部分图例：
  guides(fill = "none",
         color = guide_legend(override.aes = list(shape = 15, size=2, alpha=1)))


########### 设置一个热图数据用于绘制背景 --------
contour_data <- matrix(NA, nrow = 51, ncol = 51)
n = 0
for (i in 1:51) {
  for (j in i:51) {
    contour_data[i,j] <- n
    n = n + 1
  }
}

contour_data[lower.tri(contour_data)] <- t(contour_data)[lower.tri(contour_data)]
contour_data <- as.data.frame(contour_data)
contour_data$y <- 0:50

# 数据转换
plot_data <- pivot_longer(contour_data, cols = -y,
                          names_to = "x", values_to = "value")
plot_data$x <- rep(0:50, 51)


# 再次绘图：
p <- ggplot(data)+
  # 热图背景：
  geom_tile(data = plot_data,
            aes(x/10, y/10+5, fill = value), show.legend = F)+
  # 线条：
  geom_vline(xintercept = 0:5, color = "#cccdce")+
  geom_hline(yintercept = 5:10, color = "#cccdce")+
  geom_abline(slope = -1, intercept = 7:12, linetype = "dashed", color = "#858a8c")+
  scale_fill_gradientn(colors = c("#f8f9fe", "#c0dbec", "#8eadce"))+
  # 这个很重要，可以重复使用fill属性：
  new_scale_fill()+
  geom_point(aes(log10(mass+0.01), log10(density+0.01),
                 shape = Method, fill = `Tissue group`),
             color = "black", size = 2)+
  geom_point(aes(log10(mass+0.01), log10(density+0.01),
                 color = `Tissue group`),
             size = 0)+
  scale_shape_manual(values = c("Literature\n(histology + cytometry)" = 23,
                                "Multiplex" = 24, "Mostly extrapolation" = 21))+
  scale_fill_manual(values = c("#800000", "#cd5d5c", "#9470dc", "#006400",
                               "#2e8a57", "#fed700", "#f5f5f5", "#deb887", "#c0c0c0"))+
  scale_color_manual(name = "Tissue group",
                     values = c("#800000", "#cd5d5c", "#9470dc", "#006400",
                                "#2e8a57", "#fed700", "#f5f5f5", "#deb887", "#c0c0c0"))+
  geom_text_repel(data = data %>% arrange(desc(mass), desc(density)) %>% head(20),
                  aes(log10(mass+0.01), log10(density+0.01),
                label = tissue), size = 2)+
  scale_x_continuous(expand = c(0, 0), limits = c(0,5), breaks = 0:5,
                     labels = c(TeX("$10^{0}$"), TeX("$10^{1}$"), TeX("$10^{2}$"),
                                TeX("$10^{3}$"), TeX("$10^{4}$"), TeX("$10^{5}$")))+
  scale_y_continuous(expand = c(0, 0), limits = c(5,10), breaks = 5:10,
                     labels = c(TeX("$10^{5}$"), TeX("$10^{6}$"), TeX("$10^{7}$"),
                                TeX("$10^{8}$"), TeX("$10^{9}$"), TeX("$10^{10}$")))+
  xlab("Organ mass [g]")+
  ylab("Organ immune density [cells/g]")+
  theme_minimal()+
  theme(panel.grid = element_blank())+
  guides(fill = "none",
         color = guide_legend(override.aes = list(shape = 15, size=2, alpha=1)))

ggsave("plot.pdf", height = 5, width = 7, plot = p)
