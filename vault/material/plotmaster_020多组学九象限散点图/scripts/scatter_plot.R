######### 多组学散点图（九象限散点图） #############
# 创建示例数据(具体到你们自己的数据就是两种组学差异分析的FC值)
library(MASS)

covariance <- matrix(c(1,0.8,0.8,1),nrow=2,byrow=TRUE)
data <- mvrnorm(n=1000, mu=c(0,0), covariance)
data <- as.data.frame(data)
colnames(data) <- c("mRNA_FC", "RPF_FC")

head(data)
# mRNA_FC     RPF_FC
# [1,] -1.0069132 -1.1906012
# [2,]  1.5264603  0.6807646
# [3,] -0.7447173 -0.6654957
# [4,]  0.9627548  1.2683072
# [5,]  0.8246237  0.6616568
# [6,]  0.9687847  1.2512485

# 分组处理：设置阈值，以正负log10(2)为阈值：
group <- ifelse((abs(data[,1]) > log10(2) & abs(data[,2]) > log10(2))|(abs(data[,1]) < -log10(2) & abs(data[,2]) < -log10(2)),
                "mRNA+RPF_both", ifelse(
                  (data[,1] > log10(2) & data[,2] < log10(2) & data[,2] > -log10(2))|(data[,1] < -log10(2) & data[,2] < log10(2) & data[,2] > -log10(2)),
                "mRNA_only", ifelse(
                  (data[,2] > log10(2) & data[,1] < log10(2) & data[,1] > -log10(2))|(data[,2] < -log10(2) & data[,1] < log10(2) & data[,1] > -log10(2)),
                "RPF_only", NA)))

data$group <- group

# 绘图：
library(ggplot2)

ggplot(data)+

  


draw_axis_line <- function(length_x, length_y, 
                           tick_step = NULL, lab_step = NULL){
  axis_x_begin <- -1*length_x
  axis_x_end <- length_x
  
  axis_y_begin  <- -1*length_y
  axis_y_end    <- length_y
  
  if (missing(tick_step))
    tick_step <- 1
  
  if (is.null(lab_step))
    lab_step <- 2
  
  # axis ticks data
  tick_x_frame <- data.frame(ticks = seq(axis_x_begin, axis_x_end, 
                                         by = tick_step))
  
  tick_y_frame <-  data.frame(ticks = seq(axis_y_begin, axis_y_end, 
                                          by = tick_step))
  
  # axis labels data
  lab_x_frame <- subset(data.frame(lab = seq(axis_x_begin, axis_x_end, 
                                             by = lab_step), zero = 0), 
                        lab != 0)
  
  lab_y_frame <- subset(data.frame(lab = seq(axis_y_begin, axis_y_end,
                                             by = lab_step),zero = 0), 
                        lab != 0)
  
  # set tick length
  tick_x_length = 0.05
  tick_y_length = 0.05
  
  # set zero point
  
  data <- data.frame(x = 0, y = 0)
  p <- ggplot(data = data) +
    
    # draw axis line
    geom_segment(y = 0, yend = 0, 
                 x = axis_x_begin, 
                 xend = axis_x_end,
                 size = 0.5) + 
    geom_segment(x = 0, xend = 0, 
                 y = axis_y_begin, 
                 yend = axis_y_end,
                 size = 0.5) +
    # x ticks
    geom_segment(data = tick_x_frame, 
                 aes(x = ticks, xend = ticks, 
                     y = 0, yend = 0 - tick_x_length)) +
    # y ticks
    geom_segment(data = tick_y_frame, 
                 aes(x = 0, xend = 0 - tick_y_length, 
                     y = ticks, yend = ticks)) + 
    
    # labels
    geom_text(data=lab_x_frame, aes(x=lab, y=zero, label=lab), vjust = 1.5) +
    geom_text(data=lab_y_frame, aes(x=zero, y=lab, label=lab), hjust= 1.5) +
    theme_minimal()+
    theme(panel.grid = element_blank(),axis.text = element_blank())
  return(p)
}

p <- draw_axis_line(4, 4)

p1 <- p + geom_point(data=data, aes(mRNA_FC, RPF_FC, color = group))+
  scale_color_manual(values = c("mRNA+RPF_both" = "#dd8653", 
                                "mRNA_only" = "#59a5d7", 
                                "RPF_only" = "#aa65a4", 
                                "#878787"),
                     breaks = c("mRNA+RPF_both","mRNA_only","RPF_only"))+
  xlab("mRNA:FC(P42/E15.5)")+
  ylab("RPF:FC(P42/E15.5)")+
  theme(legend.position = "bottom")+
  annotate("text", label = "bolditalic(Brain)", parse = TRUE, 
           x = -2, y = 2, size = 4, colour = "black")+
  guides(color = guide_legend(title = "", ncol = 1, byrow = TRUE))

p1

ggsave("plot.pdf", plot = p1, height = 6, width = 5)


# 多图拼接：这里不再多画了，直接都用p1
p_list <- list(p1=p1, p2=p1, p3=p1)

library(cowplot)

p_all <- plot_grid(plotlist = p_list, ncol = 3)

ggsave("plot2.pdf", plot = p_all, height = 4, width = 9)


  