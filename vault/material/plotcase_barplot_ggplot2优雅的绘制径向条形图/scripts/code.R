library(tidyverse)

df <- read_tsv("data.tsv") %>% 
  mutate(country_name = case_when(
    receiving_country_code == "EL" ~ "Greece",  
    receiving_country_code == "UK" ~ "United Kingdom",
    receiving_country_code == "CZ" ~ "Czech Republic",
    TRUE ~ country_name)) %>% 
  group_by(country_name) %>%  
  mutate(total = sum(participants)) %>%   
  filter(row_number() == 1) %>%  # 根据分组只取1行
  arrange(desc(total)) %>%   
  ungroup() %>%  
  mutate(percent = 100 * total / sum(total)) %>%   
  mutate(country_name = factor(country_name, levels = rev(country_name))) %>% 
  head(10) 

df %>% ggplot(aes(x = country_name, y = total, fill = country_name)) +
  geom_bar(width = 0.9, stat = "identity", show.legend = FALSE) +
  scale_fill_manual(values = rep(c("#3caea3", "#173f5f"),6)) +
  coord_polar(theta = "y",start = 0) +
  labs(x=NULL,y=NULL)+
  geom_text(aes(x = country_name, y = 0,
                label = paste0(country_name, " - ", round(percent, digits = 1)," %")),
            hjust = 1.05,size=5, colour = rep(c("#173f5f","#3caea3"), 5)) +
  ylim(c(0,250)) +
  theme_void()

