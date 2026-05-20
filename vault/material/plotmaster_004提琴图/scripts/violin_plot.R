# 载入R包：
library(ggplot2)
library(ggsignif)
library(patchwork)

########## 构建data1的模拟数据：###############################
WT <- rnorm(5346,9,1)
Gain <- rnorm(877,10,1)
LOH <- rnorm(2619,9,1)
HD <- rnorm(774,5,2)

# 合并：
data <- as.data.frame(cbind(rep(c("WT","Gain","LOH","HD"),c(5346,877,2619,774)),
                            c(WT,Gain,LOH,HD)))
colnames(data) <- c("Group","Values")
data$Values <- as.numeric(data$Values)
data$Group <- factor(data$Group,levels = c("WT","Gain","LOH","HD"))
write.csv(data,"data1.csv")


# 构建加箱线图中心空格的数据：
x_value <- c(0.9, 1.1)
for (i in 1:3) {
  x_value <- append(x_value, x_value[((i-1)*2+1):(i*2)]+1)
}

med_values <- rep(c(median(data[which(data$Group == "WT"),]$Values),
                    median(data[which(data$Group == "Gain"),]$Values),
                    median(data[which(data$Group == "LOH"),]$Values),
                    median(data[which(data$Group == "HD"),]$Values)),
                  rep(2,4))

tmp_data <- as.data.frame(cbind(x_value,med_values,
                                rep(c("WT","Gain","LOH","HD"),
                                    rep(2,4))))
tmp_data$x_value <- as.numeric(tmp_data$x_value)
tmp_data$med_values <- as.numeric(tmp_data$med_values)
tmp_data$V3 <- factor(tmp_data$V3, levels = c("WT","Gain","LOH","HD"))

# 绘图:
p1 <- ggplot(data,aes(Group,Values))+
  # 提琴图：
  geom_violin(aes(fill=Group),color="white")+
  # 内部箱线图：
  geom_boxplot(fill="#a6a7ac",color="#a6a7ac",
               width = 0.1,outlier.shape = NA)+
  geom_line(data=tmp_data,aes(x_value,med_values,group=V3,color=V3),size=1.5)+
  # 填充颜色模式：
  scale_color_manual(values = c("#d1d2d2","#fbd3b9","#a1c9e5","#417bb9"))+
  scale_fill_manual(values = c("#d1d2d2","#fbd3b9","#a1c9e5","#417bb9"))+
  # 设置主题：
  theme_bw()+
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")+
  # 坐标轴label：
  xlab("Status")+
  ylab("Gene expression")+
  # y轴刻度标签：
  scale_y_continuous(breaks = seq(0,12,2))+
  # 添加注释：
  annotate("text", label = "bolditalic(MTAP)", parse = TRUE, 
           x = 3, y = 13, size = 4, colour = "black")+
  annotate("text", label = "5346",
           x = 1.3, y = 7, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "877",  
           x = 2.3, y = 8, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "2619",
           x = 3.3, y = 7, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "774",
           x = 4.3, y = 2.8, size = 4, colour = "#a6a7ac")+
  # 差异显著性检验：
  geom_signif(comparisons = list(c("LOH", "HD"), # 哪些组进行比较
                                 c("WT", "HD")),
              map_signif_level=T, # T显示显著性，F显示p值
              tip_length=c(0,0), # 修改显著性线两端的长短
              y_position = c(0,-0.5), # 设置显著性线的位置高度
              size = 0.5, # 修改线的粗细
              textsize = 4, # 修改显著性标记的大小
              extend_line = -0.1, # 线的长短：默认为0；
              color = "#a6a7ac", # 线的颜色
              test = "t.test") # 检验的类型


########## 构建data2的模拟数据：###############################
WT <- rnorm(5165,6,3)
Gain <- c(rnorm(401,4,3),rnorm(401,14,3))
Mut <- rnorm(690,9,1.5)
Mut_Gain <- rnorm(310,8.5,2)
Mut_LOH <- rnorm(119,9.5,3)
LOH <- rnorm(2302,8,5)
HD <- rnorm(1128,4,6)

data2 <- as.data.frame(cbind(rep(c("WT","Gain","Mut","Mut_Gain","Mut_LOH","LOH",
                                   "HD"),c(5165,802,690,310,119,2302,1128)),
                             c(WT,Gain,Mut,Mut_Gain,Mut_LOH,LOH,HD)))
colnames(data2) <- c("Group","Values")
data2$Values <- as.numeric(data2$Values)
data2$Group <- factor(data2$Group,
                      levels = c("WT","Gain","Mut","Mut_Gain","Mut_LOH","LOH","HD"))
write.csv(data2,"data2.csv")


# 构建加箱线图中心空格的数据：
x_value <- c(0.95, 1.05)
for (i in 1:6) {
  x_value <- append(x_value, x_value[((i-1)*2+1):(i*2)]+1)
}

med_values <- rep(c(median(data2[which(data2$Group == "WT"),]$Values),
                    median(data2[which(data2$Group == "Gain"),]$Values),
                    median(data2[which(data2$Group == "Mut"),]$Values),
                    median(data2[which(data2$Group == "Mut_Gain"),]$Values),
                    median(data2[which(data2$Group == "Mut_LOH"),]$Values),
                    median(data2[which(data2$Group == "LOH"),]$Values),
                    median(data2[which(data2$Group == "HD"),]$Values)),
                  rep(2,7))

tmp_data <- as.data.frame(cbind(x_value,med_values,
                                rep(c("WT","Gain","Mut","Mut_Gain","Mut_LOH","LOH","HD"),
                                    rep(2,7))))
tmp_data$x_value <- as.numeric(tmp_data$x_value)
tmp_data$med_values <- as.numeric(tmp_data$med_values)
tmp_data$V3 <- factor(tmp_data$V3, levels = c("WT","Gain","Mut","Mut_Gain","Mut_LOH","LOH","HD"))



p2 <- ggplot(data2,aes(Group,Values))+
  # 提琴图：
  geom_violin(aes(fill=Group),color="white")+
  # 内部箱线图：
  geom_boxplot(fill="#a6a7ac",color="#a6a7ac",
               width = 0.06,outlier.shape = NA)+
  geom_line(data=tmp_data,aes(x_value,med_values,group=V3,color=V3),size=1.5)+
  # 填充颜色模式：
  scale_color_manual(values = c("#d1d2d2","#fbd3b9","#a3c6a3","#ccdecc",
                                "#c3dbed","#a1c9e5","#417bb9"))+
  
  scale_fill_manual(values = c("#d1d2d2","#fbd3b9","#a3c6a3","#ccdecc",
                               "#c3dbed","#a1c9e5","#417bb9"))+
  # 设置主题：
  theme_bw()+
  theme(panel.grid = element_blank(),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "none")+
  # 坐标轴label：
  xlab("")+
  ylab("")+
  # 设置坐标轴范围和刻度：
  scale_y_continuous(breaks = seq(-12,26,4))+
  # 添加注释信息：
  annotate("text", label = "bolditalic(CDKN2A)", parse = TRUE, 
           x = 4, y = 26, size = 4, colour = "black")+
  annotate("text", label = "5165",
           x = 1.3, y = 2, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "802",  
           x = 2.3, y = 3, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "690",
           x = 3.3, y = 5, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "310",
           x = 4.3, y = 6, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "119", parse = TRUE, 
           x = 5.3, y = 4, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "2302",
           x = 6.3, y = 2, size = 4, colour = "#a6a7ac")+
  annotate("text", label = "1128",  
           x = 7.3, y = 2, size = 4, colour = "#a6a7ac")+
  geom_signif(comparisons = list(c("LOH", "HD"), # 哪些组进行比较
                                 c("WT", "HD")),
              map_signif_level=T, # T显示显著性，F显示p value
              tip_length=c(0,0), # 修改显著性线两端的长短
              y_position = c(-10,-12), # 设置显著性线的位置高度
              size = 0.5, # 修改线的粗细
              textsize = 4, # 修改显著性标记的大小
              extend_line = -0.05, # 
              color = "#a6a7ac",
              test = "t.test") # 检验的类型

p <- p1+p2+plot_layout(widths = c(1,2.5)) 

ggsave("violin_plot1.pdf", plot = p1, height = 5,width = 4)
ggsave("violin_plot2.pdf", plot = p2, height = 5,width = 8)
ggsave("violin_plot.pdf", plot = p, height = 6,width = 11)



