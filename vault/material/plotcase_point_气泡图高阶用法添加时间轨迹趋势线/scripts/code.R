library(tidyverse)
library(RColorBrewer)
library(ggforce)
library(ggnewscale)
library(magrittr)

sessionInfo()

df <- read_tsv("F1.tsv") %>% 
  mutate(algae.name=paste0(algae.name," (",Algae,")")) %>% 
  # 根据论文图对数据名称进行替换
  mutate(algae.name=case_when(
    algae.name =="Feb PT (FebPT)" ~ "Planklon drop",
    TRUE ~ algae.name)) %>% 
  # 根据图形介绍，数据点的大小及透明度有梯度，在此根据时间点来进行自定义
  mutate(
    size = case_when(
      Day == 0   ~ 4,Day == 7   ~ 4,
      Day == 10  ~ 5,Day == 20  ~ 6,
      Day == 40  ~ 7,Day == 200 ~ 8,
      Day == 400 ~ 10,TRUE ~ NA_real_),
    alpha = case_when(Day == 0   ~ 1,Day == 7   ~ 0.5,
                      Day == 10  ~ 0.6,Day == 20  ~ 0.7,
                      Day == 40  ~ 0.75,Day == 200 ~ 0.85,
                      Day == 400 ~ 1.0,TRUE ~ NA_real_))

# 构建颜色映射
col <- df %>% select(algae.name) %>% distinct() %>% 
  mutate(col=brewer.pal(10,"Paired")) %>% 
  deframe()

#整理曲线坐标位点

#数据如下，而我们要做的则是以algae.name为分组，筛选出每组最小day与最大day的位点信息。
#同时由于一组内每个时间点有3组重复，在此使用求均值的方法来处理

# 获取起点与终点（每组2个点）
dff <- df %>%
  group_by(algae.name,Algae,Day) %>% 
  summarise(
    NMDS1 = mean(NMDS1),
    NMDS2 = mean(NMDS2)) %>% 
  slice(c(1, n())) %>%
  filter(algae.name !="Planklon drop") %>% 
  mutate(pos = c("start", "end")) %>% 
  ungroup()

# 分别拆分数据
start_df <- dff %>% filter(pos == "start") %>%
  select(Algae,algae.name, NMDS1_start = NMDS1,
         NMDS2_start = NMDS2)

end_df <- dff %>% filter(pos == "end") %>%
  select(Algae,algae.name, NMDS1_end = NMDS1,
         NMDS2_end = NMDS2)
# 整合成曲线数据
curve_df <- left_join(start_df, end_df,
                      by = c("algae.name","Algae")) %>%
  filter(!(NMDS1_start == NMDS1_end & NMDS2_start == NMDS2_end))
# 定义弯曲度是上凹还下凸，用正负表示弯曲程度
curve_map <- tibble(
  Algae = c("d10", "d8", "d19", "d7", "d22",
            "d5", "d16", "d4", "d2"),
  curvature = c(0.3, 0.3, -0.5, -0.5,
                -0.3, 0.5, 0.5, 0.7, 0.5))
# 合并到 curve_df
curve_df2 <- curve_df %>% inner_join(curve_map, by = "Algae")

# 使用 purrr::pmap 来为每一行生成一个 geom_curve 图层
curve_layers <- pmap(curve_df2, 
                     function(NMDS1_start, NMDS2_start, NMDS1_end, NMDS2_end,
                              Algae, algae.name, curvature) {
  geom_curve(
    aes(x = NMDS1_start, y = NMDS2_start,
        xend = NMDS1_end, yend = NMDS2_end,
        color = algae.name),
    data = tibble(NMDS1_start, NMDS2_start, NMDS1_end, NMDS2_end, algae.name),
    curvature = curvature,
    arrow = arrow(length = unit(0.4, "cm"), type = "closed"),
    linewidth = 0.8,
    inherit.aes = FALSE,
    show.legend = FALSE
  )
})
# 绘图
ggplot(df, aes(x = NMDS1, y = NMDS2)) +
  geom_point(aes(fill = algae.name,color=algae.name,
                 size = size, alpha = alpha),
             shape = 21, stroke = 0) +
  scale_size_continuous(range = c(3,7)) +
  scale_fill_manual(values = col) +
  # 将所需区域的点圈起来
  geom_mark_ellipse(data=df %>% filter(Algae=="FebPT"),
                    show.legend = F,color="#FF7F00",
                    expand = unit(2,"mm")) +
  guides(size = "none", alpha = "none",color="none",
         fill = guide_legend(override.aes = list(size = 5))) +
  new_scale_color() +
  scale_color_manual(values = col) +
  guides(color = "none") +
  theme_test() +
  theme(legend.title=element_blank(),
        axis.text=element_text(color="black")) +
  curve_layers # 添加曲线图层