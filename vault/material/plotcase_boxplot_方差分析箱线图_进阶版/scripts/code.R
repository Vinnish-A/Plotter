library(tidyverse)
library(legendry)
library(ggtext)
library(multcompView)

dff <- read_tsv("data.tsv") %>% 
  mutate(`Response_Group-Flu B/Phuket HA` = factor(
    `Response_Group-Flu B/Phuket HA`,
    levels = c("low responder","middle responder","high responder")),
    Age.Group = factor(Age.Group, levels = c("Young", "Older"))) 

tex <- dff %>% group_by(`Response_Group-Flu B/Phuket HA`) %>%
  do({
    # ANOVA 模型
    fit <- aov(Adjusted_HAI.Mean_Perc_Inhib ~ Group, data = .)
    # 提取 ANOVA 表（F 值和 P 值）
    aov_tab <- summary(fit)[[1]]
    F_value <- round(aov_tab[["F value"]][1], 2)
    P_value <- aov_tab[["Pr(>F)"]][1]
    DFn <- aov_tab[["Df"]][1]
    DFd <- aov_tab[["Df"]][2]
    # Tukey 检验 + 字母分组
    tk <- TukeyHSD(fit)
    lets <- multcompLetters4(fit, tk, threshold = 0.05)
    letters_df <- tibble(
      Group = names(lets$Group$Letters),
      letters = lets$Group$Letters)
    # 合并输出
    letters_df <- letters_df %>%
      mutate(F_label = paste0("F<sub>", DFn, ",", DFd, "</sub> = ", F_value),
        P_label = ifelse(P_value < 0.001,
          "<i>P</i> < 0.001",paste0("<i>P</i> = ", signif(P_value, 3))),
        FP_label = paste0(F_label, "<br>", P_label))
  }) %>% ungroup()

# 此步主要是将绘图数据与字母整合

df2 <- dff %>% left_join(
  .,tex,by=c("Response_Group-Flu B/Phuket HA","Group"))


df2$Group <- factor(df2$Group,levels =unique(df2$Group))
df2$group2 <- factor(df2$group2,levels =unique(df2$group2))

p1 <- ggplot(df2, aes(x = interaction(Group, group2, `Response_Group-Flu B/Phuket HA`),
                      y = Adjusted_HAI.Mean_Perc_Inhib, fill = Age.Group)) +
  geom_boxplot(outlier.shape = NA, width = 0.6, lwd = 0.4) +
  scale_fill_manual(values = c(Young = "#35978f",Older = "#bf812d" )) +
  theme_classic() +
  theme(axis.text.x=element_text(angle = 90))

lab <- df2 %>%
  select(Group, group2, `Response_Group-Flu B/Phuket HA`,
         Adjusted_HAI.Mean_Perc_Inhib, letters, FP_label) %>%
  group_by(Group, group2, `Response_Group-Flu B/Phuket HA`) %>%
  slice_max(Adjusted_HAI.Mean_Perc_Inhib, n = 1, with_ties = FALSE) %>% 
  arrange(`Response_Group-Flu B/Phuket HA`) %>% 
  ungroup()
# 获取图形数据
p_build <- ggplot_build(p1)
# ymax就是我们需要的位点信息
box_data <- p_build$data[[1]] %>%
  dplyr::select(x,ymax, group) %>%
  mutate(x = as.numeric(x))
# 绘图
ggplot(df2,aes(x = interaction(Group,group2,`Response_Group-Flu B/Phuket HA`),
               y = Adjusted_HAI.Mean_Perc_Inhib))+
  geom_boxplot(aes(fill = `Age.Group`),staplewidth = 0.2,outlier.shape = NA) +
  # 添加字母标记
  geom_text(data=lab %>% mutate(y=box_data$ymax,x=box_data$x),
            aes(x=x,label=letters,y=y),vjust=-1,inherit.aes = F) +
  # 添加F,P信息
  geom_richtext(data=lab %>% group_by(`Response_Group-Flu B/Phuket HA`) %>% 
                  slice_head(n=1),
            aes(label=FP_label,y=80),fill = NA, 
            label.color = NA, # 不要背景框
            lineheight = 2,nudge_x = 3) +
  scale_fill_manual(values = c(Older="#bf812d",Young="#35978f")) +
  scale_color_manual(values = c(Older="#bf812d",Young="#35978f")) +
  scale_y_continuous(expand = expansion(mult = c(0.1, 0.15))) +
  labs(x=NULL,y="Per cent inhibition",
       title = "Flu-specific HAI by response group (2020-2021 BYam)") +
  # 分组嵌套
  guides(x = legendry::guide_axis_nested(
    type="bracket",key = key_range_auto(sep = "\\."),
    levels_text = list(
      element_blank(),
      element_markdown(angle=0,color="black"), # 最内层文本为空（x轴文本）
      # 外层分组文本属性
      element_text(angle=0,color="black",size=11,face="bold"))
  ),
  fill=guide_legend(position = "inside")) +
  theme_test() +
  theme(legend.title = element_blank(), 
        legend.position = c(0.05,0.9),
        legend.background = element_blank(),
        axis.text.y=element_text(color="black"),
        axis.line = element_line(colour = "black"),
        plot.title = element_text(vjust=0.5,hjust=0.5,color="black")) 

