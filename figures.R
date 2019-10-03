## required libraries
library(osfr)
library(tidyverse)
library(likert)
library(here)

## reading in data
osf_retrieve_file("https://osf.io/86upq/") %>% 
  osf_download(overwrite = T)

survey_data <- read_csv(here::here('cleaned_data.csv'), col_types = cols(.default = col_number(),
                                                                         ResponseId = col_character(),
                                                                         position_7_TEXT = col_character(), 
                                                                         familiar = col_factor(),
                                                                         favor_use = col_factor(),
                                                                         preprints_submitted = col_factor(),
                                                                         preprints_used = col_factor(),
                                                                         position = col_factor(),
                                                                         acad_career_stage = col_factor(),
                                                                         country = col_factor(),
                                                                         discipline = col_character(),
                                                                         discipline_specific = col_character(),
                                                                         discipline_other = col_character(),
                                                                         bepress_tier1 = col_character(),
                                                                         bepress_tier2 = col_character(),
                                                                         bepress_tier3 = col_character(),
                                                                         how_heard = col_character(),
                                                                         hdi_level = col_character(),
                                                                         UserLanguage = col_character(),
                                                                         DistributionChannel = col_character()))

## Overall icons importance

## Overall service credibilitys