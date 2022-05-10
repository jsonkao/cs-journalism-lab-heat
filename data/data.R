#' ---
#' title: "Data consolidation"
#' description: "This file consolidates all the data we need into a CSV that can be joined with the 2020 block geography."
#' author: "Jason Kao"
#' ---

#' # Libraries, helper functions

suppressPackageStartupMessages(library(tidycensus))
library(stringr)
suppressPackageStartupMessages(library(dplyr))
census_api_key('b0c03e2d243c837b10d7bb336a998935c35828af')

crosswalk <- read.csv("./crosswalk/nhgis_blk2010_blk2020.csv") %>%
  mutate(GEOID10 = as.character(GEOID10),
         GEOID20 = as.character(GEOID20))

interpolate <- function(data) {
  # Data must have columns: GEOID, group, and value
  crosswalk %>%
    inner_join(data %>% rename(GEOID10 = GEOID), by = "GEOID10") %>%
    mutate(value_weighted = value * WEIGHT) %>%
    select(GEOID = GEOID20, group, value = value_weighted) %>%
    group_by(GEOID, group) %>%
    summarize(value = sum(value, na.rm = T)) %>% 
    mutate(value = round(value, 1))
}

county <- c("Kings", "New York", "Queens", "Bronx", "Richmond")

#' # Decennial population data

# 2010 population data interpolated to 2020 blocks (asian = Asian alone)
pop10_blk20 <- get_decennial(
  geography = "block",
  state = "New York",
  county = county,
  variables = c(asian = "P003005", total = "P001001", white = "P003002", black = "P003003", hispanic = "P009002"),
  year = 2010
) %>%
  select(GEOID, group = variable, value) %>%
  interpolate() %>% 
  rename(pop = value)

# 2020 population data in 2020 blocks
pop20_blk20 <- get_decennial(
  geography = "block",
  state = "New York",
  county = county,
  variables = c(total = "P1_001N", asian = "P1_006N", white = "P1_003N", black = "P1_004N", hispanic = "P2_002N"),
  sumfile = "pl",
  year = 2020
) %>%
  select(GEOID, group = variable, pop = value)

# 2010 VAP data interpolated to 2020 blocks (asian = Asian alone)
vap10_blk20 <- get_decennial(
  geography = "block",
  state = "New York",
  county = county,
  variables = c(asian = "P010006", total = "P010001", white = "P010003", black = "P010004", hispanic = "P011002"),
  year = 2010
) %>%
  select(GEOID, group = variable, value) %>%
  interpolate() %>% 
  rename(vap = value)

# 2020 population data in 2020 blocks
vap20_blk20 <- get_decennial(
  geography = "block",
  state = "New York",
  county = county,
  variables = c(total = "P3_001N", asian = "P3_006N", white = "P3_003N", black = "P3_004N", hispanic = "P4_002N"),
  sumfile = "pl",
  year = 2020
) %>%
  select(GEOID, group = variable, vap = value)

#' # * Ommitted CVAP and ACS data for block-level analysis
#' 
#' 

#' # Join all the data

merged_data <- inner_join(
  inner_join(
    pop10_blk20,
    pop20_blk20,
    by = c("GEOID", "group"),
    suffix = c("10", "20")
  ),
  inner_join(
    vap10_blk20,
    vap20_blk20,
    by = c("GEOID", "group"),
    suffix = c("10", "20")
  ),
  by = c("GEOID", "group")
) %>% 
  tidyr::pivot_wider(names_from = group, values_from = !c(GEOID, group))

#' If we're running this on the command line, make the data wide, add some helpful variables, and save it in a file.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  merged_data %>% write.csv(args[[1]], row.names = FALSE)
}