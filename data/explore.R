#
# This file helps to explore stuff; helpful for color stuff
#

library(tidyverse)

data <- read.csv("./data/census.csv")

data %>%
  filter("36047" == substr(GEOID, 1, 5)) %>%
  select(GEOID,
         senate_unity,
         starts_with("pop20"),
         starts_with("pop10")) %>%
  mutate(in_group = senate_unity %in% c("G")) %>% 
  pivot_longer(
    starts_with("pop"),
    names_to = c(".value", "group"),
    names_pattern = "(.*)_(.*)"
  ) %>%
  group_by(in_group, group) %>%
  summarize(pop10 = sum(pop10), pop20 = sum(pop20), pct_growth = (pop20 - pop10) / pop10)

# Can this be right? Growth outside of G was 50%? I think it's right. Shied I needa change my argument then