################# 构建数据 ########################
# FMI的数据：先创建随机字母组合表示癌症的原发位置和转移位置：
FMI <- cbind(LETTERS[sample(1:10,1000,replace = T)],LETTERS[sample(1:10,1000,replace = T)])

# 计算每种癌症内部转移至其它部位的比例：
percent <- unlist(tapply(FMI[,2], FMI[,1], function(x) table(x)/length(x)))

# 合并数据：
data_FMI <- as.data.frame(cbind(rep(LETTERS[1:10],rep(10,10)), rep(LETTERS[1:10],10)))
data_FMI$percent <- percent

# 同样的方法构建MSK的数据：
MSK <- cbind(LETTERS[sample(1:10,1000,replace = T)],LETTERS[sample(1:10,1000,replace = T)])

percent <- unlist(tapply(MSK[,2], MSK[,1], function(x) table(x)/length(x)))

data_MSK <- as.data.frame(cbind(rep(LETTERS[1:10],rep(10,10)), rep(LETTERS[1:10],10)))
data_MSK$percent <- percent


# 合并：
data <- cbind(data_FMI, data_MSK[,3])
colnames(data) <- c("primary","metastasis","percent_FMI","percent_MSK")

# 再构建一列，用于表达转移瘤的样本量；
data$meta_num <- c(sample(1:10,80, replace = T), sample(20:40,20, replace = T))

########################## 绘图 ##############################
library(ggplot2)

ggplot(data,aes(percent_MSK, percent_FMI))+
  geom_smooth(method="lm", 
              se=F, # 置信区间
              colour="#999999",
              linetype="dashed") +
  geom_point(aes(color=metastasis,fill=primary, 
                 size=meta_num),shape=21)+
  theme_classic()+
  scale_fill_manual(values = c("#d0db50","#8e94b8","#5fa0ca","#bddef3","#a0c0dd",
                               "#78b885","#fbed3e","#f08c41","#efd232","#ca414c"))+
  scale_color_manual(values = c("#d0db50","#8e94b8","#5fa0ca","#bddef3","#a0c0dd",
                               "#78b885","#fbed3e","#f08c41","#efd232","#ca414c"))+
  theme(legend.position = "none")


############ 发现相关性几乎为0，调整数据 ##################
# 给同类型的比例排个序，相关性就高了，但是实际分析过程不能这么做！！！
data$percent_FMI <- unlist(tapply(data$percent_FMI, data$primary, 
                                  function(x) sort(x,decreasing = T)))

data$percent_MSK <- unlist(tapply(data$percent_MSK, data$primary, 
                                  function(x) sort(x,decreasing = T)))

Hmisc::rcorr(data$percent_FMI, data$percent_MSK)

# 去掉未转移的行：
data <- data[data$primary != data$metastasis,]

ggplot(data,aes(percent_MSK, percent_FMI))+
  geom_smooth(method="lm", 
              se=F, # 置信区间
              colour="#999999",
              linetype="dashed",
              alpha=0.2,
              size=0.5) +
  geom_point(aes(color=metastasis,fill=primary, 
                 size=meta_num),shape=21,
             stroke=1 # 描边粗细
             )+
  theme_classic()+
  scale_fill_manual(values = c("#d0db50","#8e94b8","#5fa0ca","#bddef3","#a0c0dd",
                               "#78b885","#fbed3e","#f08c41","#a988be","#fa9fb5"))+
  scale_color_manual(values = c("#d0db50","#8e94b8","#5fa0ca","#bddef3","#a0c0dd",
                                "#78b885","#fbed3e","#f08c41","#a988be","#fa9fb5"))+
  theme(legend.position = "none")+
  xlab("Metastatic Site % in MSK(2919)")+
  ylab("Metastatic Site % in FMI(4100)")+
  annotate(geom = "text", x=0.10, y=0.17,
           label = "R = 0.862, P = 1.04e-41")

ggsave("scatter_plot.pdf",height = 6,width = 6)



