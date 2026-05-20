devtools::install_local('./jjPlot-main.zip')

library(jjPlot)
library(readxl)
library(jjAnno)

data <- read_excel("pnas.2120787119.sd06.xlsx", sheet = 2)
colnames(data) <- data[1,]
data <- data[-1,]


data_long <- data[,c(1:2,4,3,10:11)] %>% 
  pivot_longer(cols = `Mutations not in this subtype`:`Mutations in this subtype`, 
               names_to = "Mutations_type",
               values_to = "Mutations_number") %>% 
  mutate(group = rep(1:780, each = 2))

data_long$`Correlation Type`[seq(1,1559, 2)] <- "Grey"
data_long$Subtype <- factor(data_long$Subtype, levels = rev(unique(data_long$Subtype)))
data_long$`Mutated Gene` <- factor(data_long$`Mutated Gene`, levels = unique(data_long$`Mutated Gene`))
data_long$Mutations_number <- as.numeric(data_long$Mutations_number)
colnames(data_long) <- gsub(" ", "_", colnames(data_long))
data_long$Grobname <- rep(paste0("c", 1:6), c(40, 200, 160, 180, 100, 100)*2)

head(data_long)
# # A tibble: 6 × 8
# Mutated_Gene Subtype Q.value            Corre…¹ Mutat…² Mutat…³ group Grobn…⁴
# <fct>        <fct>   <chr>              <chr>   <chr>     <dbl> <int> <chr>  
#   1 NOTCH1       G1      2.424644496862920… Grey    Mutati…      88     1 c1     
# 2 NOTCH1       G1      2.424644496862920… Exclus… Mutati…     111     1 c1     
# 3 NOTCH1       G2      0.764067251463119… Grey    Mutati…       1     2 c1     
# 4 NOTCH1       G2      0.764067251463119… Not si… Mutati…      10     2 c1     
# 5 NOTCH1       G3      1                  Grey    Mutati…       3     3 c1     
# 6 NOTCH1       G3      1                  Not si… Mutati…       7     3 c1 

# 绘图：
p <- ggplot(data_long, aes(x = Mutated_Gene,
                 y = Subtype,
                 group = group)) +
  geom_jjPointPie(aes(pievar = Mutations_number,
                      fill = Correlation_Type), 
                  width = 0.4,
                  color = NA,
                  line.size = 0)+
  scale_fill_manual(values = c("Co-occurrence" = "#cc0000",
                               "Exclusivity" = "#0090b4",
                               "Grey" = "#dddddd",
                               "Not significant" = "#666666"))+
  scale_y_discrete(expand = c(0.02,0.02))+
  theme_minimal()+
  xlab("")+
  ylab("")+
  theme(axis.text.x = element_text(angle = 90, hjust=1, vjust = 0,
                                   face = "italic"),
        panel.grid = element_blank(),
        legend.position = "none",
        plot.margin = margin(t = 2,r = 1, l = 1, b = 1, unit = 'cm'))+
  coord_cartesian(clip = 'off')

p1 <- annoSegment(object = p,
            annoPos = 'top',
            aesGroup = T,
            aesGroName = 'Grobname',
            yPosition = 10.5,
            segWidth = 0.5,
            pCol = rep("black", 6),
            addBranch = T,
            addText = T,
            textCol = rep("black", 6),
            textSize = 10,
            lwd = 1,
            branDirection = -1)

ggsave("plot.pdf", plot = p1, height = 6, width = 15)


