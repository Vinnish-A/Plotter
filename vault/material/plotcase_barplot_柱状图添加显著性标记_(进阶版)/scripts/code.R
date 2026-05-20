library(tidyverse)
library(ggpubr)
library(rstatix) 
library(ggprism)

df <- read_tsv("data.tsv")

df_long <- df %>%
  pivot_longer(-RNA, names_to = "Sample",values_to = "Expression") %>%
  mutate(Group = case_when(
    str_detect(Sample, "Col0") ~ "Col0",
    str_detect(Sample, "val1-2") ~ "val1-2",
    str_detect(Sample, "glk1glk2val1") ~ "glk1;glk2;val1",
    str_detect(Sample, "glk1glk2") ~ "glk1;glk2"))

df_long$Group <- factor(
  df_long$Group, levels = c("Col0","val1-2","glk1;glk2", "glk1;glk2;val1"))

df_long$RNA <- factor(df_long$RNA ,levels = unique(df_long$RNA))

# 以Col0 为参照进行t.test(),使用原始p不矫正
pva <- df_long %>%  group_by(RNA) %>%
  rstatix::t_test(Expression ~ Group, ref.group = "Col0",
                  var.equal = FALSE) %>%
  mutate(signif_raw = case_when(p < 0.001 ~ "***",p < 0.01 ~ "**",
                                p < 0.05 ~ "*",TRUE ~ "ns")) %>% 
  rstatix::add_xy_position(x = "RNA", dodge = 0.9) %>% 
  select(-y.position)

# 计算每一个柱子的最高点用于添加*
top_y <- df_long %>% group_by(RNA, Group) %>%
  summarise(
    mean_expr = mean(Expression),
    se_expr = sd(Expression) / sqrt(n()),
    y.position = mean_expr + se_expr,
    .groups = "drop") %>% filter(Group!="Col0") %>% 
  select(1,2, y.position)
# 联接数据
pva1 <- pva %>%
  left_join(.,top_y,by=c("RNA"="RNA","group2"="Group")) %>% 
  filter(signif_raw !="ns") 

# 统计分析_2
# glk1;glk2”,“glk1;glk2;val1” 间进行t.test(),使用原始p不矫正
pva2 <- df_long %>% 
  group_by(RNA) %>% 
  rstatix::t_test(Expression ~ Group,var.equal = FALSE) %>% 
  mutate(signif_raw = case_when(
    p < 0.001 ~ "***",p < 0.01 ~ "**",p < 0.05 ~ "*",
    TRUE ~ "ns")) %>% 
  rstatix::add_xy_position(x = "RNA", dodge = 0.9) %>% 
  # 筛选分析结果保留所需的组
  filter(group2 %in% c("glk1;glk2","glk1;glk2;val1"),
         group1 %in% c("glk1;glk2","glk1;glk2;val1"),
         RNA !="GUN4") %>% 
  # 定义y.position信息使用之前计算的top_y数据
  mutate(y.position=top_y %>% 
           filter(Group=="glk1;glk2;val1",RNA !="GUN4") %>%
           mutate(y.position=y.position+0.2) %>% 
           pull(y.position))

df_long %>% 
  ggplot(.,aes(RNA, Expression)) +
  stat_summary(aes(fill=Group),
               fun="mean",geom="bar",size = 3,width = 0.8,
               position = position_dodge(0.9)) +
  # 绘制误差条，表示均值 ± 标准误
  stat_summary(aes(fill=Group),
               fun.data = "mean_se",
               geom = "errorbar", width = 0.3,
               position = position_dodge(0.9)) +
  geom_point(aes(,fill=Group),pch=18,size=5,alpha=0.5,color=I("grey60"),
             position = position_dodge(0.9),show.legend = F)+
  geom_text(data=pva1,aes(x=xmax,label=signif_raw,y=y.position),
            inherit.aes = F,size=6,
            position = position_dodge(0.9),hjust=0.5,vjust=0)+
  add_pvalue(pva2,xmin="xmin",xmax="xmax", # 设置显著性标注的横坐标起点和终点
             label = "signif_raw", 
             label.size = 6,hide.ns = T, 
             tip.length = c(0.12,0.02)) +
  scale_y_continuous(expand= expansion(mult = c(0,0.1)),
                     name="RNA leves (fold vs Col0)") +
  scale_fill_manual(values =c("Col0" = "#4D4D4D",
                              "val1-2" = "#D95F02",
                      "glk1;glk2" = "#FFD92F",
                      "glk1;glk2;val1" = "#66C2A5")) +
  labs(x=NULL) +
  theme_test()+
  theme(legend.background = element_blank(),
        legend.key = element_blank(),
        legend.title = element_blank(),
        legend.position = c(0.92,0.82),
        legend.text = element_text(face="italic",color="black"),
        axis.text.x=element_text(color="black",face="bold"))