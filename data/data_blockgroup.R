#' ---
#' title: "Data consolidationn"
#' description: "This file consolidates all the data we need into a CSV that can be joined with the 2020 block group geography."
#' author: "Jason Kao"
#' ---

#' # Libraries, helper functions

suppressPackageStartupMessages(library(tidycensus))
library(stringr)
suppressPackageStartupMessages(library(dplyr))
census_api_key('b0c03e2d243c837b10d7bb336a998935c35828af')

crosswalk <- read.csv("./crosswalk/crosswalk.csv") %>%
  mutate(blk_group10 = as.character(blk_group10),
         blk_group20 = as.character(blk_group20))

interpolate <- function(data) {
  # Data must have columns: GEOID, group, and value
  crosswalk %>%
    inner_join(data %>% rename(blk_group10 = GEOID), by = "blk_group10") %>%
    mutate(value_weighted = value * weight) %>%
    select(GEOID = blk_group20, group, value = value_weighted) %>%
    group_by(GEOID, group) %>%
    summarize(value = sum(value, na.rm = T)) %>% 
    mutate(value = round(value, 1))
}

county <- c("Kings", "New York", "Queens", "Bronx", "Richmond")

#' # Decennial population data

# 2010 population data interpolated to 2020 block groups (asian = Asian alone)
pop10_bg20 <- get_decennial(
  geography = "block group",
  state = "New York",
  county = county,
  variables = c(asian = "P003005", total = "P001001", white = "P003002", black = "P003003", hispanic = "P009002"),
  year = 2010
) %>%
  select(GEOID, group = variable, value) %>%
  interpolate() %>% 
  rename(pop = value)

# 2020 population data in 2020 block groups
pop20_bg20 <- get_decennial(
  geography = "block group",
  state = "New York",
  county = county,
  variables = c(total = "P1_001N", asian = "P1_006N", white = "P1_003N", black = "P1_004N", hispanic = "P2_002N"),
  sumfile = "pl",
  year = 2020
) %>%
  select(GEOID, group = variable, pop = value)

# 2010 VAP data interpolated to 2020 block groups (asian = Asian alone)
vap10_bg20 <- get_decennial(
  geography = "block group",
  state = "New York",
  county = county,
  variables = c(asian = "P010006", total = "P001001", white = "P010003", black = "P010004", hispanic = "P011002"),
  year = 2010
) %>%
  select(GEOID, group = variable, value) %>%
  interpolate() %>% 
  rename(vap = value)

# 2020 population data in 2020 block groups
vap20_bg20 <- get_decennial(
  geography = "block group",
  state = "New York",
  county = county,
  variables = c(total = "P3_001N", asian = "P3_006N", white = "P3_003N", black = "P3_004N", hispanic = "P4_002N"),
  sumfile = "pl",
  year = 2020
) %>%
  select(GEOID, group = variable, vap = value)

#' # CVAP Data

#' Notable columns:
#' - CIT_EST: rounded estimate of total number of citizens
#' - CVAP_EST: rounded estimate of total number of citizens >= 18 years old
#'
#' Also: I don't think these both are actually on 2010 Decennial block group geography. It [seems like](https://www.census.gov/programs-surveys/acs/geography-acs/geography-boundaries-by-year.html) they're updated every year...

read_cvap <- function(fname) {
  data <- read.csv(fname)
  if ("LNTITLE" %in% colnames(data)) {
    data <- data %>% select(GEOID, group = LNTITLE, value = CVAP_EST)
  } else {
    data <- data %>% select(GEOID = geoid, group = lntitle, value = cvap_est)
  }
  data %>%
    mutate(GEOID = substr(GEOID, 8, 19)) %>%
    mutate(group = str_replace(group, "Asian Alone", "asian")) %>%
    mutate(group = str_replace(group, "White Alone", "white")) %>%
    mutate(group = str_replace(group, "Black or African American Alone", "black")) %>%
    mutate(group = str_replace(group, "Hispanic or Latino", "hispanic")) %>%
    mutate(group = str_replace(group, "Total", "total")) %>%
    filter(group %in% c("asian", "black", "hispanic", "white", "total")) %>% 
    interpolate() %>% 
    rename(cvap = value)
}

cvap10_bg20 <- read_cvap("./cvap/CVAP_2010.csv")
cvap19_bg20 <- read_cvap("./cvap/CVAP_2019.csv")

#' # ACS Data
#' 
#' > load_variables(2019, "acs5", cache = T) %>% View
#' 
#' - Language: Table C16002 (household-level language ability. Easier to start with than B16004, individual-level)
#'   - Variables: total households and total limited english speaking households that speak Asian/PI languages
#' - Income: median household income
#' - Education: B28006 = Educational Attainment By Presence Of A Computer And Types Of Internet Subscription In Household
#' - Government benefits: B19123 = Family Size By Cash Public Assistance Income Or Households Receiving Food Stamps/Snap Benefits In The Past 12 Months

get_acs_nyc <- function(vars, name = "", geo = "block group") {
  data <- get_acs(
    geography = geo,
    state = "New York",
    county = county,
    variables = vars,
    year = 2019
  ) %>% 
    select(GEOID, group = variable, estimate)
  if (length(vars) == 1) {
    data %>%
      rename(!!name := estimate) %>% 
      select(-group) %>% 
      return()
  } else if (name != "") {
    data %>%
      tidyr::pivot_wider(names_from = group, names_glue = paste0(name, "_{group}"), values_from = estimate) %>% 
      return()
  }
}

hhlang <- get_acs_nyc(c(total = "C16002_001", asian = "C16002_010"), "hhlang") # 'asian' means API language HHs with LEP

income <- get_acs_nyc(c(total = "B19013_001"), "income")

# TODO: incorporate internet subscription and presence of a computer
education <- get_acs_nyc(c(total = "B28006_001", no_hs = "B28006_002", hs_grad = "B28006_008", ba_above = "B28006_014"), "graduates")

benefits <- get_acs_nyc(c(total = "B19123_001", benefits = "B19123_002"), "families")

#' # ACS Data I'm fine with at the tract level

# TODO: B05007: Place Of Birth By Year Of Entry By Citizenship Status For The Foreign-Born Population

entry <- get_acs_nyc(
  c(total = "B05007_027", `2010_later` = "B05007_028", `2000_2009` = "B05007_031", `1990_1999` = "B05007_034", `1990_earlier` = "B05007_037"),
  "asiaentry",
  "tract"
)
workers <- get_acs_nyc(c(total = "B08006_001", publictransport = "B08006_008", drove = "B08006_002"), "workers", "tract") 

#' # Consolidate static variables

static_consolidated <-
  hhlang %>%
  inner_join(income) %>%
  inner_join(education) %>%
  inner_join(benefits) %>% 
  mutate(tract = substr(GEOID, 1, 11)) %>% 
  right_join(entry %>% rename(tract = GEOID), by = "tract") %>% 
  right_join(workers %>% rename(tract = GEOID), by = "tract") %>% 
  select(-tract)

#' # Consolidate dynamic variables

dynamic_consolidated <- inner_join(
  cvap10_bg20,
  cvap19_bg20,
  by = c("GEOID", "group"),
  suffix = c("10", "19")
) %>%
  inner_join(
    inner_join(
      inner_join(
        pop10_bg20,
        pop20_bg20,
        by = c("GEOID", "group"),
        suffix = c("10", "20")
      ),
      inner_join(
        vap10_bg20,
        vap20_bg20,
        by = c("GEOID", "group"),
        suffix = c("10", "20")
      ),
      by = c("GEOID", "group")
    ),
    by = c("GEOID", "group")
  ) %>% 
  tidyr::pivot_wider(names_from = group, values_from = !c(GEOID, group))

#' # Generating desirable output

output <- full_join(static_consolidated, dynamic_consolidated, by = "GEOID")

#' If we're running this on the command line, make the data wide, add some helpful variables, and save it in a file.

args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0) {
  output %>% write.csv(args[[1]], row.names = FALSE)
}