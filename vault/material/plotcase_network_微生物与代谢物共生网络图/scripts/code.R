library(igraph)   
library(ggpubr) 
library(tidyverse) 

sessionInfo()

unzip("input.zip")

# 三个 habitat 名称
graph_names <- c("Bog","Fen","Palsa")
# 读取节点与边文件路径
node_files <- list.files("./input", "node_table_annotated",
                         full.names=TRUE)[c(3,1,2)]   # 节点表

edge_files <- list.files("./input", "\\.sif$",
                         full.names=TRUE)[c(3,1,2)]  # 边表

# 给文件加名字，方便后续对应 habitat
names(node_files) <- graph_names
names(edge_files) <- graph_names

# 提取所有代谢物元素组成类型，用于统一配色
elcomps <- map(node_files, ~read_tsv(.x) %>%
                 filter(str_detect(Name,"mass")) %>%          # 只取代谢物节点
                 pull(Phylum_Elcomposition)) %>%             # 提取元素组成
  unlist() %>% unique()  # 合并去重
# 为不同元素组成生成调色板
elcomp_colors <- set_names(get_palette("Paired", length(elcomps)), elcomps)
# 定义颜色
elcomp_colors[c("CHO","CHNO","CHOS","CHOSP","CHNOSP")] <-
  c("#A6CEE3","#CCCCFF","#FF9900","yellow","#33FF00")


# 构建三张网络图（igraph 对象）
network_graphs <- map2(node_files, edge_files, function(nf, ef){
  # 读取并处理节点表
  nodes <- read_tsv(nf) %>%
    mutate(
      # 元素组成着色
      color = replace_na(elcomp_colors[Phylum_Elcomposition],"white"), 
      size = ifelse(str_detect(Node_type,"Peripheral"),4.5,10),   # 外围节点更小
      frame.color = "black",  # 黑色描边
      # hub 描边更粗
      frame.width = ifelse(str_detect(Node_type,"Peripheral"),1,2),  
      shape = ifelse(str_detect(Name,"mass"),"circle","square"))      # 代谢物/微生物区分形状
    
  # 读取并处理边表 
  edges <- read_tsv(ef, col_names=c("from","direction","to")) %>%
    transmute(
      from, to,
      # 正负相关着色
      color = ifelse(direction=="pp","steelblue","indianred"),       
      edge.width = 3)    # 边宽度
  #  构建 igraph 对象 
  graph_from_data_frame(edges, vertices=nodes, directed=FALSE)
})



# 导出进入网络的微生物列表
networked_bacteria <- imap(node_files, function(nf, hab){
  read_tsv(nf) %>%
    filter(str_detect(Name,"micro")) %>%   # 只保留微生物节点
    mutate(Habitat = hab)                  # 添加对应 habitat
  
}) %>%
  bind_rows()                              # 合并三种 habitat

write_csv(networked_bacteria, "networked_bacteria.csv")

# 设置布局
par(mfrow=c(1,3),            # 1 行 3 列
    mar=c(0,0,2,0),         # 上方留空间放标题
    oma=c(6,1,0,1),         # 底部预留 legend 空间
    bg=NA)                  # 透明背景

# 绘制三张网络图，并添加顶部 habitat 标题
Map(function(g, nm){
  plot(g,
       rescale=TRUE,        # 自动缩放网络
       vertex.label=NA,    # 关闭所有节点文字
       main=nm,            # Bog / Fen / Palsa 标题
       col.main="white",   # 标题白色（黑底）
       cex.main=1.4)       # 标题大小
}, network_graphs, graph_names)
# 关闭多 panel 模式
par(mfrow=c(1,1))
# 在整张画布底部单独绘制图例
par(fig=c(0,1,0,1), new=TRUE)
plot.new()

legend("bottom",inset=-0.15,                 # 图例整体下移
       fill=elcomp_colors,         # 元素组成颜色
       legend=names(elcomp_colors),
       ncol=4,                     # 四列排列
       bg="white",                 # 白色背景
       bty="n",                    # 取消边框
       cex=0.8,
       y.intersp = 1.2, 
       xpd=NA)                     # 允许绘制到画布外

dev.off()
