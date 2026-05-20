library(tidyverse)
library(lubridate)
library(ggstream)
library(glue)
library(RColorBrewer)
library(scales)
library(ggtext)
library(geomtextpath)

sessionInfo()

data <- read_csv("data.csv", 
                 name_repair = function(x) {
                   str_to_lower(x)
                 })

long <- data %>% filter(`-9` != 100) %>%
  mutate(good_date = ymd(str_sub(date, 3, 10))) %>%
  pivot_longer(cols = c(3:13), names_to = "cat") %>%
  select(-c(1:2)) %>%
  filter(cat != "-9") %>%
  mutate(cat = factor(cat,levels = c(glue("d{0:4}"),glue("w{0:4}"))))

ylabs <- tibble(
  x = c("1895-09-01",glue("{seq(from = 1920, to = 2000, by = 20)}-01-01"),
        "2022-03-01")) %>% mutate(x = ymd(x),y = 125,yend = -125,
         lab = year(x),hjust = c(0,0,0,.5,1,1,1),
         vjust = c(-.5, .5,.5, 1, 1, .5, -.5))

long %>% mutate(value = ifelse(str_detect(cat, "^w"),
                               value * -1, value)) %>%
  ggplot(aes(good_date, value, fill = cat)) +
  annotate(geom = "rect", xmin = ymd("2015-01-01"), xmax = ymd("2021-01-01"),
           ymin = -110, ymax = 100,fill="grey40") +
  geom_segment(data = ylabs,
               aes(x = x, xend = x, y = y-5, yend = yend),
               color = "grey50", inherit.aes = FALSE) +
  geom_text(data = ylabs,aes(x = x, y = y, label = lab, 
                hjust = hjust, vjust = vjust),
            color = "black",inherit.aes = FALSE)+
  geom_area(position = "identity") +
  scale_y_continuous(labels = function(x) glue("{abs(x)}%"),
                     limits = c(-1000, NA))+
  scale_x_date(expand = c(0.02, 0))+
  scale_fill_manual(values=c("#67001F","#B2182B","#D6604D","#F4A582","#FDDBC7","#D1E5F0",
                             "#92C5DE","#4393C3","#2166AC","#053061"))+
  coord_curvedpolar(clip = "off")+
  theme_void()+
  theme(text = element_text(color="black"),
        legend.position = c(.5,.5),
        legend.title = element_blank(),
        legend.key.size = unit(1,"lines")) +
  guides(fill = guide_legend(
    ncol = 2, byrow = TRUE,
    label.theme = element_text(color = "black",size = 8)))


