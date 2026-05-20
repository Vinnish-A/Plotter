library(ggvenn)
library(tidyverse)  
library(ggtext)
library(ggsankeyfier)
library(cowplot)

sessionInfo()

plot_venn <- function(n_a_only, n_b_only, n_c_only,
                       n_ab, n_ac, n_bc, n_abc,
                       set_names = c("Set A", "Set B", "Set C"),
                       fill_color = c("#E15759", "#F28E2B", "#4E79A7"),
                       title = "3-Set Venn Diagram") {
  # 生成唯一 ID
  a_only <- paste0("A_", seq_len(n_a_only))
  b_only <- paste0("B_", seq_len(n_b_only))
  c_only <- paste0("C_", seq_len(n_c_only))
  ab   <- paste0("AB_", seq_len(n_ab))
  ac   <- paste0("AC_", seq_len(n_ac))
  bc   <- paste0("BC_", seq_len(n_bc))
  abc  <- paste0("ABC_", seq_len(n_abc))
  # 构建集合
  venn_data <- list(c(a_only, ab, ac, abc),
    c(b_only, ab, bc, abc),
    c(c_only, ac, bc, abc)) %>% set_names(set_names)
  # 绘制 Venn
  ggvenn(venn_data,
    fill_color = fill_color,
    stroke_color="white",stroke_size = 0,
    set_name_size = 4,text_size = 4,
    show_percentage = FALSE) 
}

p1 <- plot_venn(
  n_a_only = 370, n_b_only = 3150, n_c_only = 11947,
  n_ab = 240, n_ac = 594, n_bc = 3836, n_abc = 539,
  set_names = c("Downregulated\n genes in CFL1_KO",
                "ATAC loss in CFL1-,\nYTHDC2-or MLL1-KO"," ")) +
  coord_cartesian(clip="off") +
  annotate("segment", x = 0.1, y = 0.2,   # 起点坐标
           xend = 2, yend = 0.2,  # 终点坐标
           colour = "#8B0000",
           arrow = arrow(length = unit(0.2, "cm"), type = "closed"),
           size = 0.8) +
  labs(caption = "Hyper-m<sup>6</sup>A seRNA-associated genes<br><br>
       in 65 PDAC samples (r > 0.3, p < 0.0001)") +
  theme_void() +
  theme(plot.caption =element_markdown(
          margin = margin(-0.8,unit="cm"),hjust=0.5,size=12,color="black"))
# 构建桑基图数据
df <- data.frame(
  source = rep("Target genes (n=539)", 11),
  target = c("Hypoxia", "mTORC1 signaling", "Apical junction",
             "Epithelial mesenchymal transition", "TGF-β signaling",
             "Apoptosis", "IL-2/STAT5 signaling", "P53 pathway",
             "ROS pathway", "Glycolysis", "PI3K/AKT/mTOR signaling"),
  counts = c(50, 40, 30, 60, 45, 35, 40, 25, 30, 55, 60))
# 数据格式转换
dff <- df %>% pivot_stages_longer(stages_from=c("source","target"),
                            values_from = "counts")

p2 <- ggplot(data = dff,aes(x=stage,y=counts,group = node,
                      edge_id = edge_id,connector = connector)) + 
  geom_sankeyedge(aes(fill = node),alpha=0.9,
    position=position_sankey(order="descending",align = 'center',
                             v_space = "auto", width = 0)) +
  geom_sankeynode(aes(fill=node,color=node),
                  position=position_sankey(align = 'center',
                    order="descending",v_space="auto",width=0.1)) +
  geom_text(data=dff %>% filter(connector== "from"),
            aes(label=node),stat="sankeynode",
            position=position_sankey(
              v_space="auto",order="descending",nudge_y = 100),
            vjust=0.5,hjust=0.5,size=4,color="black",angle=90) +
  geom_text(data=dff %>% filter(connector== "to"),
            aes(label=node),stat="sankeynode",
            position=position_sankey(
              v_space="auto",order="descending",nudge_x=0.06),
            hjust=0,size=3.5,color="black") +
  theme_void() +
  theme(legend.position = "none",
        plot.margin = margin(0.5,1,0.5,0,unit="cm"))
# 拼图
plot <- ggdraw() +
  draw_plot(p1 +  theme(legend.position = "none",
                        plot.margin = margin(1,10,0.5,0,unit="cm"))) +
  draw_plot(p2,scale = 0.9,x=0.35,height = 1,width=0.7)

plot