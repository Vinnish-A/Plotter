library(openxlsx)
library(scatterplot3d)
library(pheatmap)
library(ggplot2)
library(plot3D)
library(RColorBrewer)

plot.data <- read.xlsx( "Figure4A-DiffusionMap.xlsx" )
plot.data[1:5, 1:5]
#           ID Group   color        DC_1       DC_2
# 1 SIHTALLS26    G1 #FD6AB0 -0.02677773 0.03531621
# 2        A37    G1 #FD6AB0 -0.03068308 0.04230065
# 3        T78    G1 #FD6AB0 -0.02738485 0.03747457
# 4  SIHTALLS3    G1 #FD6AB0 -0.02941009 0.04039534
# 5 SIHTALLS12    G1 #FD6AB0 -0.01946934 0.02060690

# plot3D包：
pdf("plot1.pdf", width = 10, height = 10)
with(plot.data, scatter3D(x = DC_1, y = DC_3, z = DC_2,
                     pch = 21, cex = 1.5,
                     col = "white",
                     xlab = "DC_1",
                     ylab = "DC_3",
                     zlab = "DC_2", 
                     bg = plot.data$color,
                     ticktype = "detailed",
                     bty = "f", box = T,
                     theta = -20, phi = 0, d=3,
                     colkey = FALSE))
dev.off()

## gg3D包绘制：
# devtools::install_local("gg3D-master.zip")
library(gg3D)

theta <- -20
phi <- 0
colors <- unique(plot.data$color)
names(colors) <- colors
pdf("plot2.pdf", width = 7, height = 7)
ggplot(plot.data, aes(x = DC_1, y = DC_3, z = DC_2, color = color)) + 
  axes_3D(theta=theta, phi=phi) + 
  stat_3D(theta=theta, phi=phi) +
  labs_3D(theta=theta, 
          phi=phi, 
          hjust=c(1,1,0), 
          vjust=c(1.5,1,-.2),
          labs=c("DC_1", "DC_2", "DC_3")) +
  scale_color_manual(values = colors)+
  theme_void()+
  theme(legend.position = "none")
dev.off()

# scatterplot3d包：
pdf("plot3.pdf", width = 7, height = 7)
scatterplot3d(x = plot.data$DC_1, 
              y = plot.data$DC_3, 
              z = plot.data$DC_2,
              color = plot.data$color,
              pch = 16, cex.symbols = 1,
              scale.y = 0.7, angle = 120,
              xlab = "DC_1", ylab = "DC_3", zlab = "DC_2",
              col.axis = "#444444", col.grid = "#CCCCCC")
dev.off()
