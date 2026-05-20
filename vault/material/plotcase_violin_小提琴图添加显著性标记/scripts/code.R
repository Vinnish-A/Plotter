library(tidyverse)
library(ggh4x)
library(rstatix)
library(ggpubr)

# 数据读取
df <- read_tsv("data.tsv") %>% mutate(year=as.character(year))
# 定义因子调整顺序
df$continent <- factor(df$continent,levels = c("Asia","Americas","Europe"))
# 按大洲进行统计分析
df_p_val1 <- df %>% group_by(continent)%>%
  wilcox_test(lifeExp ~year) %>%
  adjust_pvalue(p.col="p",method="bonferroni") %>%
  add_significance(p.col="p.adj") %>% 
  add_xy_position(x="year",dodge=0.8)
# 绘图
df %>% ggplot(aes(year,lifeExp))+
  geom_violin(aes(fill=continent),trim = FALSE,show.legend = F)+
  geom_boxplot(width = 0.2,outliers = FALSE, staplewidth = 0.5) +
  scale_y_continuous(sec.axis = sec_axis(~ ., name = ""))+
  # 添加均值点
  stat_summary(fun=mean,geom="point",col="black",fill="#F98400",
               shape=23,show.legend = F)+
  # 添加连接线
  stat_summary(fun=mean, geom="line",aes(group=continent), col="black")+
  stat_pvalue_manual(df_p_val1,label="p.adj.signif",hide.ns=T,
                     tip.length = 0,label.size = 5,color="black")+
  # 分面
  facet_nested_wrap(
    . ~ continent,strip = strip_nested(
      background_x = elem_list_rect(fill=c("#3B9AB2","#7294D4","#E6A0C4")))) +
  # 定义填充颜色
  scale_fill_manual(values = c("#3B9AB2","#7294D4","#E6A0C4"))+
  # 设置Y轴刻度风格
  guides(y = guide_axis(minor.ticks = TRUE)) +
  labs(x=NULL,y=NULL)+
  theme(axis.text.x=element_text(angle = 0,vjust=0.5,hjust=0.5,color="black"),
        axis.text.y=element_text(color="black"),
        plot.background = element_rect(fill="white"), 
        panel.background = element_rect(fill="white"),
        panel.spacing.x = unit(0,"cm"),
        strip.background = element_rect(color="white",linewidth = 0.5),
        plot.margin=unit(c(0.5,0.5,0.5,0.5),unit="cm"),
        axis.line.x=element_line(color="black"),
        axis.line.y.left = element_line(color="grey30"),
        axis.line.y.right = element_line(color="grey30"),
        axis.text.y.right = element_blank(),
        axis.ticks.y.right = element_blank())
  
