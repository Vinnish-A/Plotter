library(tidyverse)
library(ggplot2)

# 数据构建 ------------
sd <- runif(100, min = 1.5, max = 3)
data <- data.frame(high = runif(100, -2, 8))
data$low = data$high - sd
data$mean <- apply(data, 1, mean)

data <- round(data, 2)

# x轴信息：
data$x <- rep(paste0("sample", 1:25), 4)

# 两种分组信息：
data$group1 <- rep(c("FPG", "GSP", "FINS", "HOMA-IR"), each = 25)
data$group2 <- rep(rep(c("Blood OPEs", "Urine OPEs"), c(18, 7)), 4)

# 颜色信息通过显著性指定 -- 此处随机创建：
pos_ind <- sample(which(data$mean > 0), 20)
neg_ind <- sample(which(data$mean < 0), 15)

data$Trend <- "Not Significant"
data$Trend[pos_ind] <- "Positive"
data$Trend[neg_ind] <- "Negative"

data$Signif <- ifelse(data$Trend == "Not Significant", "", "*")

write.csv(data, "data.csv")

# 绘图 --------------------
p <- ggplot(data)+
  geom_hline(yintercept = 0, linetype = "dashed", color = "#999999")+
  geom_linerange(aes(x, ymin = low, ymax = high, color = Trend))+
  geom_point(aes(x, mean, color = Trend), shape = 21, fill = "white")+
  geom_text(aes(x, high+0.1, label = Signif), color = "black", size = 3)+
  scale_color_manual(values = c("Not Significant" = "#999999",
                                "Positive" = "#b70031",
                                "Negative" = "#0097c4"))+
  scale_y_continuous(breaks = seq(-2, 5, 2))+
  xlab("")+
  ylab("Percentage change(%)")+
  facet_grid(group1 ~ group2, scales = "free", space = "free_x")+
  theme_bw()+
  theme(panel.grid = element_blank(),
        legend.position = "top",
        axis.text.x = element_text(angle = 90, hjust = 1, vjust = 0.5),
        strip.text = element_text(color = "white", face = "bold"),
        strip.background.x = element_rect(fill = "#008ea0"),
        strip.background.y = element_blank()
        )

p

# 通过grid底层绘图系统修改分面颜色(这段代码非常复杂，看不懂的可以跳过)：
# 如果不理解，就直接用AI调更方便；
data$facet_color_y <- rep(c("#0073c2", "#efc000", "#cd534c", "#8f7700"),
                          each = 25)
p_tmp <- p

p_tmp$layers <- NULL
p_tmp <- p_tmp + geom_rect(data=data,
                           xmin=-Inf, ymin=-Inf,
                           xmax=Inf, ymax=Inf,
                           aes(fill = facet_color_y))+
  scale_fill_manual(values = c("#0073c2", "#efc000", "#cd534c", "#8f7700"))

library(gtable)

g1 <- ggplotGrob(p)
g2 <- ggplotGrob(p_tmp)

gtable_select <- function (x, ...)
{
  matches <- c(...)
  x$layout <- x$layout[matches, , drop = FALSE]
  x$grobs <- x$grobs[matches]
  x
}

panels <- grepl(pattern="panel", g2$layout$name)
strips <- grepl(pattern="strip-r", g2$layout$name)
g2$grobs[strips] <- replicate(sum(strips), nullGrob(), simplify = FALSE)
g2$layout$l[panels] <- g2$layout$l[panels] + 3
g2$layout$r[panels] <- g2$layout$r[panels] + 4

new_strips <- gtable_select(g2, panels | strips)
grid.newpage()
grid.draw(new_strips)

gtable_stack <- function(g1, g2){
  g1$grobs <- c(g1$grobs, g2$grobs)
  g1$layout <- rbind(g1$layout, g2$layout)
  g1
}

new_plot <- gtable_stack(g1, new_strips)
grid.newpage()
grid.draw(new_plot)

pdf("plot.pdf", height = 5, width = 7)
grid.draw(new_plot)
dev.off()











