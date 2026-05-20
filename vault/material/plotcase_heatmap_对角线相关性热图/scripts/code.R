library(tidyverse)
library(legendry)
library(readxl)
library(magrittr)
library(corrplot)
library(RColorBrewer)
library(grid)

sessionInfo()

df1 <- read_excel("41586_2025_9686_MOESM8_ESM.xlsx",sheet="Fig4l") %>%
  set_colnames(c("subjectGuid","CD4 T cell","CD8 T cel",
                 "Total_IgG_D7","Total_IgG_D0","IgG2/IgG3_Ratio_D0",
                 "IgG2_IgG3_Ratio_D7","Response_Score",
                 "IgG2_Total_IgG")) %>% select(-1) %>% 
    mutate(across(everything(), ~replace_na(.x, 0)))

cor_mat <- cor(df1, method = "spearman",use = "pairwise.complete.obs")
cor_long <- as.data.frame(as.table(cor_mat))

names(cor_long) <- c("fact1","fact2","r")
lev <- colnames(cor_mat)

cor_data <- cor_long %>%
  mutate(
    i = match(fact1, colnames(cor_mat)),    #把 fact1 转换成对应的列索引
    j = match(fact2, colnames(cor_mat))    # 把 fact2 转换成对应的行索引
  ) %>%
  filter(j >= i)  # 只保留下三角的数据

# 构建对角线文本
diag_labels <- tibble(
  fact1 = factor(lev, levels = lev),
  fact2 = factor(lev, levels = rev(lev)),label = lev)

plot <- ggplot(cor_data, aes(x = fact1,y = fact2)) +
  geom_tile(color = "grey50",linewidth = 0.6,fill="white") +
  geom_point(aes(color=r,size=r),pch=19) +
  scale_y_discrete(limits = rev(levels(factor(cor_data$fact2)))) +
  geom_text(data = diag_labels,
            aes(fact1, fact2, label = label),inherit.aes = F,
            hjust = 0, vjust = 1,nudge_x=-0.2,nudge_y = 0.6,
            size = 10,angle=90,size.unit = "pt",
            color=c(rep("tomato",2),rep("#7294D4",6))) +
  scale_color_gradientn(limits = c(-1,1),na.value = NA,
                        colours = rev(RColorBrewer::brewer.pal(11,"RdBu")),
                        name = "Spearman's r") +
  scale_size_continuous(range = c(8,11)) +
  coord_cartesian(clip="off") +
  guides(size="none",color=guide_colorbar(
           barwidth=unit(0.5,"cm"),barheight=unit(5,"cm"))) +
  theme_minimal(base_size = 12) +
  theme(axis.text.x = element_blank(),
        plot.margin = margin(2,1,0.5,2,unit="cm"),
        axis.text.y=element_text(color=c(rep("#7294D4",6),rep("tomato",2)),
                                 vjust=0.5,hjust=1),
        panel.grid = element_blank(),
        axis.title = element_blank(),
        legend.frame = element_rect(color="black"),
        legend.background = element_blank(),
        legend.title = element_text(color="black",size=10,vjust=0.5,hjust=1),
        legend.text=element_text(color="black",size=10)) +
  annotation_custom( # 添加线条注释
    grob=grid.segments(gp=gpar(col="tomato",lwd=10)),
    xmin=-1.7,xmax=-1.7,ymin=6.7,ymax=8.3) +
  annotation_custom( # 添加线条注释
    grob=grid.segments(gp=gpar(col="#7294D4",lwd=10)),
    xmin=-3.5,xmax=-3.5,ymin=1,ymax=6) +
  annotation_custom(
  grob = grid.text(label="RNA age\nmetric (up)",hjust=0,vjust=0,rot=0,
                   gp=gpar(col="tomato",fontsize=10)),
  xmin=-3.6,xmax=-3.6,ymin=7.2,ymax=7.2) +
  annotation_custom(
  grob = grid.text(label="BYam\n2020-2021",hjust=0,vjust=0,rot=90,
                   gp=gpar(col="#7294D4",fontsize=10)),
  xmin=-3.9,xmax=-3.9,ymin=3,ymax=3) 

plot

col_custom <- colorRampPalette(rev(brewer.pal(11, "RdBu")))(200)

cor(df1,method = "spearman",use = "pairwise.complete.obs") %>% 
  corrplot(type="lower",
           col=col_custom,
           tl.srt = 90,
           tl.col = c(rep("tomato",2),rep("#7294D4",6)),
           tl.cex = 0.8,
           cl.ratio=0.2,
           cl.length = 5,   # 刻度数量 
           cl.pos = "r")