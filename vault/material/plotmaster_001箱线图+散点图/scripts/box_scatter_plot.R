# 创建虚拟数据：
Bacteroides_thetaiotaomicron_R <- runif(23, min = -17, max = -12)
Bacteroides_thetaiotaomicron_G <- runif(23, min = -15.5, max = -10)
BMI_R <- runif(23, min = 3.45, max = 4.2)
BMI_G <- runif(23, min = 3.2, max = 4.0)
data <- cbind(Bacteroides_thetaiotaomicron_G,BMI_G,Bacteroides_thetaiotaomicron_R,BMI_R)

# 加载包：
library(ggplot2)
library(tidyr)

# 对数据进行简单处理：
new_data <- as.data.frame(rbind(data[1:23,3:4],data[1:23,1:2]))
colnames(new_data) <- c("Bacteroides_thetaiotaomicron","BMI")
new_data$group <- rep(c("group_0M","group_3M"),c(23,23))
new_data$group2 <- rep(paste("sample",1:23,sep=""),2)

# 绘制散点图：
ggplot(new_data)+
  # 绘制基本散点图
  geom_point(aes(Bacteroides_thetaiotaomicron, BMI,color=group))+
  # 设置颜色
  scale_color_manual(values = c(group_0M="#ff00ff", group_3M="#8ac53e"))+
  # 设置主题
  theme_classic()+
  # 设置坐标轴范围
  scale_x_continuous(breaks = c(-17:11))+
  scale_y_continuous(breaks = seq(3.2,4.0,0.2))+
  # 设置x轴和y轴标签
  xlab("Bacteroides thetaiotaomicron (11021)")+
  ylab("BMI(lg)")+
  # 去掉图例：
  theme(legend.position = 'none')

ggsave(filename = "scatter_plot.pdf",height=5,width = 5)

# 绘制左边的箱线图：
ggplot(new_data,aes(group, BMI))+
  # 加上误差棒；由于自带的箱形图没有胡须末端没有短横线，使用误差条的方式补上
  stat_boxplot(geom = "errorbar",width=0.15,aes(color=group))+ 
  # 绘制基本箱线图
  geom_boxplot(aes(color=group),fill="white")+
  # 加上散点之间的连线
  geom_line(aes(group=group2), color="black",linetype="dashed",size=0.2, alpha=0.8)+
  # 箱线图加散点
  geom_jitter(aes(color=group,fill=group),width =0.05,shape = 21)+ #设置为向水平方向抖动的散点图，width指定了向水平方向抖动，不改变纵轴的值
  # 设置颜色
  scale_color_manual(values = c(group_0M="#ff00ff", group_3M="#8ac53e"))+
  scale_fill_manual(values = c(group_0M="#ff00ff", group_3M="#8ac53e"))+
  # 设置主题
  theme_classic()+
  # 设置坐标轴范围
  scale_x_discrete(labels=c("0M","3M"))+
  scale_y_continuous(breaks = seq(3.2,4.0,0.2))+
  # 设置x轴和y轴标签
  xlab("")+
  ylab("")+
  # 去掉图例：
  theme(legend.position = 'none')

ggsave(filename = "left_boxplot.pdf",height=5,width = 2)


# 绘制下面的箱线图：
ggplot(new_data,aes(group, Bacteroides_thetaiotaomicron))+
  # 加上误差棒；由于自带的箱形图没有胡须末端没有短横线，使用误差条的方式补上
  stat_boxplot(geom = "errorbar",width=0.15,aes(color=group))+ 
  # 绘制基本箱线图
  geom_boxplot(aes(color=group),fill="white")+
  # 加上散点之间的连线
  geom_line(aes(group=group2), color="black", linetype="dashed", size=0.2, alpha=0.8)+
  # 箱线图加散点
  geom_jitter(aes(color=group,fill=group),width =0.05,shape = 21)+ #设置为向水平方向抖动的散点图，width指定了向水平方向抖动，不改变纵轴的值
  # 设置颜色
  scale_color_manual(values = c(group_0M="#ff00ff", group_3M="#8ac53e"))+
  scale_fill_manual(values = c(group_0M="#ff00ff", group_3M="#8ac53e"))+
  # 设置主题
  theme_classic()+
  # 设置坐标轴范围
  scale_x_discrete(labels=c("0M","3M"))+
  scale_y_continuous(breaks = c((-17):(-11)))+
  # 设置x轴和y轴标签
  xlab("")+
  ylab("")+
  # 去掉图例
  theme(legend.position = 'none')+
  # 旋转坐标轴
  coord_flip()

ggsave(filename = "down_boxplot.pdf",height=2,width = 5)

