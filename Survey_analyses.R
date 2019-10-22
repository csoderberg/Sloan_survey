##required libraries
library(osfr)
library(tidyverse)
library(here)

## reading in data
osf_retrieve_file("https://osf.io/86upq/") %>% 
  osf_download(overwrite = T)

survey_data <- read_csv(here::here('cleaned_data.csv'), col_types = cols(.default = col_number(),
                                                                         StartDate = col_datetime(format = '%m/%d/%y %H:%M'),
                                                                         EndDate = col_datetime(format = '%m/%d/%y %H:%M'),
                                                                         ResponseId = col_character(),
                                                                         position_7_TEXT = col_character(), 
                                                                         familiar = col_factor(),
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
                                                                         discipline_collapsed = col_factor(),
                                                                         how_heard = col_character(),
                                                                         hdi_level = col_factor(),
                                                                         age = col_character())) %>%
                mutate(hdi_level = fct_relevel(hdi_level, c('low', 'medium', 'high', 'very high')),
                       preprints_used = fct_relevel(preprints_used, c('Not sure', 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       preprints_submitted = fct_relevel(preprints_submitted, c('Not sure', 'No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       familiar = fct_relevel(familiar, c('Not familiar at all', 'Slightly familiar', 'Moderately familiar', 'Very familiar', 'Extremely familiar')),
                       acad_career_stage = fct_relevel(acad_career_stage, c('Grad Student', 'Post doc', 'Assist Prof', 'Assoc Prof', 'Full Prof')))

#### basic sample characteristics ####

# total sample
nrow(survey_data)

# familiarity level of sample
survey_data %>% group_by(familiar) %>% tally()

# favorability level of sample
survey_data %>% 
  group_by(favor_use) %>% 
  tally()

100*sum(survey_data$favor_use < 0, na.rm = T)/nrow(survey_data) #percentage unfavorable
100*sum(survey_data$favor_use == 0, na.rm = T)/nrow(survey_data) #percentage neutral
100*sum(survey_data$favor_use > 0, na.rm = T)/nrow(survey_data) #percentage favorable

# preprint usage
survey_data %>% 
  group_by(preprints_submitted) %>% 
  tally()

survey_data %>% 
  group_by(preprints_used) %>% 
  tally()

# demographics #
survey_data %>% 
  group_by(acad_career_stage) %>% 
  tally()

survey_data %>% 
  group_by(discipline_collapsed) %>% 
  tally()

survey_data %>% 
  group_by(hdi_level) %>% 
  tally()

#### correlates of favorability ####
r_and_cis <- survey_data %>%
  select(starts_with('preprint_cred'), favor_use) %>%
  corr.test(adjust = 'none')

r_and_cis$ci %>%
  rownames_to_column(var = 'correlation') %>%
  filter(grepl('fvr_s', correlation)) %>%
  column_to_rownames('correlation') %>%
  select(-p) %>%
  round(digits = 2)
  