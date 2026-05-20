library(tidyverse)

df <- tibble::tibble(
  receptor = c("ITGA2/ITGA6/ITGA9/CD44/DAG1",
               "ITGA2/ITGA6/ITGA9",
               "ITGA1/ITGA2/ITGA6/CD44",
               "CD44",
               "ITGA2/ITGA3/ITGA6/DAG1",
               "ITGA1/CD44/DAG1",
               "ITGA1/CD44/DAG1"),
  celltype = c("T cells","Macrophages","Mesenchymal stem cells",
               "Neutrophils","Proliferative UTCs","Fibroblasts",
               "Binucleate trophoblast cells")) %>% 
  mutate(id=seq(7,1,by=-1))

dff <- df %>% pivot_longer(-id) %>% 
  mutate(name=factor(name,levels = c("receptor","celltype")))

edges <- df %>%  transmute(
    x = 1.1, y = unique(dff$id),
    xend = 1.9, yend = unique(dff$id))

df2 <- data.frame(Ligen="LAMM3EB",
           x=0.1,xend=0.8,y=4,yend=c(1:7))

df3 <- data.frame(x=-0.9,y=c(2,6),celltype=c("UTC3","UTC2"),
           xend=-0.6,yend=4)

plot <- ggplot(dff,aes(name,id)) +
  geom_point(data=dff %>% filter(name=="receptor"),
             pch=22,fill="grey",color="black",size=6)+
  geom_point(data=dff %>% filter(name!="receptor"),
             aes(color=value),pch=1,size=6,stroke = 1) +
  geom_point(data=dff %>% filter(name!="receptor"),
             aes(color=value),pch=16,size=4,stroke = 0) +
  geom_segment(data = edges,aes(x = x, y = y, xend = xend, yend = yend),
              color = "grey50")+
  geom_text(data=dff %>% filter(name=="receptor"),
            aes(label=value,y=id),hjust=0,vjust=-1.5,nudge_x =-0.2) +
  geom_text(data=dff %>% filter(name!="receptor"),
            aes(label=value,y=id),hjust=0,vjust=0.5,nudge_x =0.1) +
  geom_point(data=df2,aes(y=y),x=-0.5,inherit.aes = F,
             pch=22,fill="grey",color="black",size=6) +
  geom_segment(data=df2,aes(x=x,xend=xend,y=y,yend=yend),
               linetype=2) +
  geom_segment(data=df2,x=-0.4,xend=0.1,y=4,yend=4,linetype=2) +
  geom_text(data=df2,aes(x=-0.4,y=4,label=Ligen),fontface="bold",
            vjust=-1,inherit.aes = F) +
  geom_segment(data=df3,aes(x=x,xend=xend,y=y,yend=yend),linetype=1) +
  geom_point(data=df3,aes(
    x=x-0.05,y = ifelse(y >4, y + 0.2, y - 0.2)),
    inherit.aes = F,
             pch=1,size=6,stroke = 1,color="#e74c3c") +
  geom_point(data=df3,aes(
    x=x-0.05,y = ifelse(y >4, y + 0.2, y - 0.2),
    color=celltype),inherit.aes = F,
             pch=16,size=4,stroke = 0) +
  geom_text(data=df3,aes(
    x=x-0.1,y = ifelse(y >4, y + 0.2, y - 0.2),label=celltype),
            hjust=1,vjust=0.5,nudge_x =-0.02) +
  coord_cartesian(cli="off") +
  theme_void() +
  theme(plot.margin = margin(1,4,0.5,2,unit="cm"),
        legend.position = "none")

plot