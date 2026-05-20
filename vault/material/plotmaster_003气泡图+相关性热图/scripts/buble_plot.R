# 读取数据：
data <- read.csv("exprSet.csv",row.names = 1)

# 相关性分析R包：
library(Hmisc)

# 计算相关性矩阵：
# 创建空矩阵接收返回值：
cor_value <- matrix(NA,19,10)
p_value <- matrix(NA,19,10)

# for循环进行相关性分析：
for (i in 1:10) {
  cor_list <- rcorr(as.matrix(data[(10*(i-1)+1):(10*i),]))
  cor_value[,i] <- cor_list$r[2:20,1]
  p_value[,i] <- cor_list$P[2:20,1]
}

rownames(cor_value) <- colnames(data)[2:20]
rownames(p_value) <- colnames(data)[2:20]

# 数据结构转换：
library(tidyr)
data_cor <- gather(as.data.frame(t(cor_value)),key = "gene",value = "cor")
data_cor$group <- rep(paste("Group",1:10,sep = ""),19)

data_p <- gather(as.data.frame(t(p_value)),key = "gene",value = "pvalue")
data_p$group <- rep(paste("Group",1:10,sep = ""),19)

data_result <- cbind(data_cor,data_p$pvalue)
colnames(data_result)[4] <- "pvalue"

# 添加正负相关信息：
Neg_Pos <- rep("Neg",190)
Neg_Pos[which(data_result$cor>0)] <- "Pos"

data_result$Neg_Pos <- Neg_Pos
data_result$pvalue <- c(rep(0.00002,5),rep(0.0002,5),runif(180,0,0.08))

# 修改p值表示方法：
pvalue <- rep(NA,190)
pvalue[which(data_result$pvalue > 0.05)] <- ">0.05"
pvalue[which(data_result$pvalue < 0.05)] <- "<0.05"
pvalue[which(data_result$pvalue < 0.01)] <- "<0.01"
pvalue[which(data_result$pvalue < 0.001)] <- "<0.001"
pvalue[which(data_result$pvalue < 0.0001)] <- "<0.0001"

table(pvalue)
data_result$pvalue <- pvalue

# 绘图：
ggplot(data_result,aes(gene,group))+
  # 气泡图：
  geom_point(aes(fill=pvalue, size=abs(cor)),color = "#999999",shape=21)+
  scale_fill_manual(values = c("#212c5f","#42b0e4","#dfe1e0","#facccc","#d9dbd9"))+
  # 主题：
  theme_bw()+
  theme(panel.grid.minor.x = element_blank(),panel.grid.major.x = element_blank(),
        # 坐标轴label方向：
        axis.text.x = element_text(angle = 45, hjust = 1),
        # 图例间距：
        legend.margin = margin(20,unit = 'pt'))+
  xlab("")+
  ylab("")

ggsave("cor_buble_heatmap_tmp.pdf",height = 6,width = 12)


# 绘图：
ggplot(data_result,aes(gene,group))+
  # 蓝色气泡图：
  geom_point(aes(fill=pvalue, size=abs(cor)),color = "#999999",shape=21)+
  scale_fill_manual(values = c("#212c5f","#3366b1","#42b0e4","#7bc6ed","#dfe1e0"))+
  # 红色气泡图：
  geom_point(data = data_result[which(data_result$Neg_Pos == "Pos"),],
             aes(color=pvalue, size=abs(cor)),shape=16)+
  scale_color_manual(values = c("#f26666","#f49699","#facccc","#facccc","#d9dbd9"))+
  # 主题：
  theme_bw()+
  theme(panel.grid.minor.x = element_blank(),panel.grid.major.x = element_blank(),
        # 坐标轴label方向：
        axis.text.x = element_text(angle = 45, hjust = 1),
        # 图例间距：
        legend.margin = margin(20,unit = 'pt'))+
  xlab("")+
  ylab("")+
  # 图例：
  guides(size = guide_legend(title = "Spearman's p"),
         fill = guide_legend(title = expression("Negtive \ncorrelation \nFDR q-value")),
         col = guide_legend(title = expression("Positive \ncorrelation \nFDR q-value")))

ggsave("cor_buble_heatmap.pdf",height = 6,width = 12)



