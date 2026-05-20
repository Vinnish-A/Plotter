# 载入R包+数据读取
library(ggplot2)

data <- read.csv("TableS3.csv")
data$Glycometabolic.markers <- factor(data$Glycometabolic.markers,
                                      levels = c("FPG", "GSP", "FINS", "HOMA-IR"))
data[1:5, 1:3]
#   Glycometabolic.markers Quantile.midpoint Line.predication
# 1                    FPG              0.13             0.77
# 2                    FPG              0.38             0.82
# 3                    FPG              0.63             0.86
# 4                    FPG              0.88             0.91
# 5                    GSP              0.13             2.49

########### 绘图 ---------------
p <- ggplot(data)+
  geom_ribbon(aes(Quantile.midpoint, ymin = Low.limit.of.simulation,
                  ymax = Up.limit.of.simulation,
                  fill = Glycometabolic.markers), alpha = 0.2)+
  geom_line(aes(Quantile.midpoint, Line.predication,
                color = Glycometabolic.markers))+
  geom_point(aes(Quantile.midpoint, Line.predication),
             shape = 21, color = "#7f7f7f", fill = "white")+
  geom_errorbar(aes(Quantile.midpoint, ymin = Low.limit.of.line.predication,
                    ymax = Up.limit.of.linpred),
                color = "#7f7f7f", width = 0.05)+
  scale_fill_manual(values = c("#0073c2", "#efc000", "#cd534c", "#8f7700"))+
  scale_color_manual(values = c("#0073c2", "#efc000", "#cd534c", "#8f7700"))+
  facet_wrap(~ Glycometabolic.markers, nrow = 1, scale = "free_y")+
  xlab("Joint exposure quantile")+
  ylab("Y")+
  scale_x_continuous(breaks = seq(0.00, 1.00, 0.25),
                     labels = seq(0.00, 1.00, 0.25))+
  theme_classic()+
  theme(legend.position = "none",
        strip.text = element_text(color = "white", face = "bold"),
        strip.background.x = element_blank())
p

# 通过grid底层绘图系统修改分面颜色(这段代码非常复杂，看不懂的可以跳过)：
# 如果不理解，就直接用AI调更方便；
data$facet_color_y <- rep(c("#0073c2", "#efc000", "#cd534c", "#8f7700"),
                          each = 4)
p_tmp <- p

p_tmp$layers <- NULL
p_tmp <- p_tmp + geom_rect(data=data,
                           xmin=-Inf, ymin=-Inf,
                           xmax=Inf, ymax=Inf,
                           aes(fill = facet_color_y))+
  scale_fill_manual(values = c("#0073c2", "#efc000", "#cd534c", "#8f7700"))

library(gtable)
library(grid)

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
strips <- grepl(pattern="strip-t", g2$layout$name)
g2$grobs[strips] <- replicate(sum(strips), nullGrob(), simplify = FALSE)
g2$layout$t[panels] <- g2$layout$t[panels] - 1
g2$layout$b[panels] <- g2$layout$b[panels] - 2

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

pdf("plot.pdf", height = 2.3, width = 8)
grid.draw(new_plot)
dev.off()

