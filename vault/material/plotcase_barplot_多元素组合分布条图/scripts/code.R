library(readxl)
library(tidyverse)
library(patchwork)

sessionInfo()

prod <- read_excel("43016_2026_1303_MOESM3_ESM.xlsx", sheet = 1)
cons <- read_excel("43016_2026_1303_MOESM3_ESM.xlsx", sheet = 2)

# 计算net
# 贸易隐含净排放量（Net trade-embedded emissions）
prod_total <- prod %>% group_by(Region) %>%
  summarise(Production = sum(
    `PROD_EMIS(Mt)`,na.rm = TRUE),.groups = "drop")

cons_total <- cons %>% group_by(Region) %>%
  summarise(Consumption = sum(
    `CONS_EMIS(Mt)`, na.rm = TRUE),.groups = "drop")

net_df <- prod_total %>% left_join(cons_total, by = "Region") %>%
  mutate(Net = Consumption - Production)

# 定义颜色
food_cols <- c(
  "Grains" = "#EFD532",
  "Oil crops and nuts" = "#89A948",
  "Other plant products" = "#94D1A4",
  "Beef" = "#D67A7A",
  "Dairy" = "#EEE7D8",
  "Other animal products" = "#E8B7C3")
# 定义因子
region_levels <- c(
  "CHN","WE","IND","SSA","MENA","USA","ROLA","ROSEA",
  "BRA","ROSA","IDN","RUS","EE","JPN","OCE","ROEA","CAN")

food_levels <- c("Grains","Oil crops and nuts","Other plant products",
  "Beef","Dairy","Other animal products")

prod$Region <- factor(prod$Region, levels = rev(region_levels))
cons$Region <- factor(cons$Region, levels = rev(region_levels))
net_df$Region  <- factor(net_df$Region,  levels = rev(region_levels))

prod$FOOD_CAT <- factor(prod$FOOD_CAT, levels = food_levels)
cons$FOOD_CAT <- factor(cons$FOOD_CAT, levels = food_levels)

# 绘制左侧图
p1 <- ggplot(data=prod %>% left_join(net_df %>% filter(Net < 0),by="Region"),
             aes(x = -`PROD_EMIS(Mt)`, y = Region, fill = FOOD_CAT)) +
  geom_col(width = 0.82, color = "#777777", linewidth = 0.35) +
  geom_point(aes(x=Net,y=Region),inherit.aes = F,
             size=5,fill="#EFD532",color="grey60",pch=21,stroke = 1) +
  scale_y_discrete(position = "right") +
  scale_x_continuous(expand = expansion(mult = c(0.01,0))) +
  scale_fill_manual(values = food_cols, drop = FALSE) +
  labs(title = "production") +
  theme_classic() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank(),
    plot.title = element_text(vjust=0.5,hjust=1),
    legend.position = "none",
    axis.text.y.right=element_text(color="black",vjust = 0.5,hjust=0.5,
                                   margin = margin(l=0.3,unit="cm")),
    axis.title = element_blank(),
    axis.ticks.y = element_blank())

# 绘制右侧图
p2 <- ggplot(cons %>% left_join(net_df %>% filter(Net > 0),by="Region"),
             aes(x =  `CONS_EMIS(Mt)`, y = Region, fill = FOOD_CAT)) +
  geom_col(width = 0.82, color = "#777777", linewidth = 0.35) +
  geom_point(aes(x=Net,y=Region),inherit.aes = F,
             size=5,fill="#EFD532",color="grey60",pch=21,stroke = 1) +
  scale_x_continuous(expand = expansion(mult = c(0,0.1))) +
  scale_fill_manual(values = food_cols, drop = FALSE) +
  labs(title="consumption") +
  theme_classic() +
  theme(
    panel.background = element_blank(),
    panel.grid = element_blank(),
    legend.title = element_blank(),
    legend.position = c(1.6,1),     # 右上角坐标
    legend.justification = c(1,1),
    legend.background = element_blank(),
    axis.text.y=element_blank(),
    axis.title = element_blank(),
    axis.ticks.y = element_blank(),
    plot.title = element_text(vjust=0.5,hjust=0),
    plot.margin = margin(r=5,unit="cm"))
# 绘制饼图
pie_df <- read_excel("43016_2026_1303_MOESM3_ESM.xlsx",sheet = 3) %>% 
  mutate(FOOD_CAT = factor(FOOD_CAT))

pie <- ggplot(pie_df, aes(x = "", y = `EMISSION(Mt)`, fill = FOOD_CAT)) +
  geom_col(width = 1, color = "#666666", linewidth = 0.8) +
  coord_polar(theta = "y") +
  geom_text(aes(label = sprintf("%.2f", `EMISSION(Mt)`)),
    position = position_stack(vjust = 0.5),size = 3,color="black") +
  scale_fill_manual(values = food_cols, drop = FALSE) +
  labs(title = "Global emissions (Mt)") +
  theme_void() +
  theme(legend.position = "none",
        plot.title = element_text(size = 11, hjust = 0.5))
# 拼图
plot <- (p1|p2)+
  inset_element(pie,left = 0.7,right = 1.5,
                bottom = 0,top = 0.6)

plot

ggsave(plot,file="plot.pdf",width=8.58,height=4.95,unit="in")

