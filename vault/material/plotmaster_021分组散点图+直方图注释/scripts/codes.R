# 创建示例数据(具体到你们自己的数据就是两种组学差异分析的FC值)
library(MASS)

covariance <- matrix(c(1,-0.2,-0.2,1), nrow=2, byrow=TRUE)
data <- mvrnorm(n=1000, mu=c(0.5, 3), covariance)
data <- as.data.frame(data)
colnames(data) <- c("Genome size", "GC content")

# 查看数据情况：
plot(data$`Genome size`, data$`GC content`)

# 添加分组信息：
data$group <- "Host unknown"
data$group[order(data$`Genome size`)[c(sample(10:30, 10),
                                       sample(500:1000, 300))]] <- "Bacteroidetes"
data$group[order(data$`Genome size`)[c(sample(30:60, 20),
                                       sample(200:800, 300))]] <- "Firmicutes"
data$group[order(data$`Genome size`)[c(sample(40:80, 20),
                                       sample(100:200, 20))]] <- "Actinobacteria"
data$group[order(data$`Genome size`)[sample(1:1000, 10)]] <- "Proteobacteria"

head(data)
# Genome size GC content          group
# 1   0.9136138   3.351591     Firmicutes
# 2   0.9569283   4.865890     Firmicutes
# 3   1.3357191   3.311626  Bacteroidetes
# 4  -1.3002559   4.492414 Actinobacteria
# 5  -0.2020433   2.203683   Host unknown
# 6  -0.5626978   2.839346   Host unknown

# 绘图：
# 方法一：使用psych包绘制
library(psych)
with(data, scatter.hist(`Genome size`, `GC content`))

data_tmp <- data

colnames(data_tmp) <- c("Genome_size", "GC_content", "group")
scatter.hist(Genome_size ~ GC_content, data = data_tmp)

scatter.hist(Genome_size ~ GC_content, #增加分组变量
             data=data_tmp,
             xlab="Genome size", #行坐标名
             ylab="GC content", #纵坐标名
             density = F,
             ab=F, #增加拟合直线
             correl=F,  #删除右上角的相关系数
             smooth=F,  #删除平滑曲线
             grid=F,   #删除网格线
             ellipse=F   #删除椭圆
)

# 方法二：使用ggplot2绘制：
library(ggplot2)

p1 <- ggplot(data)+
  geom_point(aes(`Genome size`, `GC content`, color = group))+
  scale_color_manual(values = c("Bacteroidetes" = "#ffbe5d",
                                "Firmicutes" = "#82a0c3",
                                "Actinobacteria" = "#f28c88",
                                "Proteobacteria" = "#77bda1",
                                "Host unknown" = "#d6d6d6"))+
  theme_classic()+
  theme(legend.position = c(0.99,0.99),
        legend.justification = c(1,1))+
  guides(colour = guide_legend(""))


# 上方直方图：
p2 <- ggplot(data)+
  geom_histogram(aes(`Genome size`), 
                 binwidth = 0.2, 
                 fill = "#9db1c1",
                 color = "#ffffff",
                 size = 1)+
  theme_classic()+
  xlab("")+
  ylab("# of vOTUs")


# 右侧直方图：
p3 <- ggplot(data)+
  geom_histogram(aes(`GC content`), 
                 binwidth = 0.2, 
                 fill = "#9db1c1",
                 color = "#ffffff",
                 size = 1)+
  theme_classic()+
  xlab("")+
  ylab("# of vOTUs")+
  coord_flip()


# 拼图：
library(cowplot)

p <- ggdraw() + 
  draw_plot_label("a", size = 20)+
  # 四个数值中前两个代表左下角位置：
  # 后两个代表图形宽和高：
  draw_plot(p1, 0.05, 0, .75, .8)+
  draw_plot(p2, 0.05, 0.8, .75, .2)+
  draw_plot(p3, 0.8, 0, .2, .8)

ggsave("plot.pdf", height = 5, width = 8, plot = p)



