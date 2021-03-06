##required libraries
library(osfr)
library(tidyverse)
library(here)
library(psych)
library(MOTE)
library(lmerTest)
library(lavaan)
library(semTools)
library(broom)
library(tidyLPA)
library(semPlot)

## reading in data
osf_retrieve_file("https://osf.io/86upq/") %>% 
  osf_download()

all_survey_data <- read_csv(here::here('cleaned_data.csv'), col_types = cols(.default = col_number(),
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
                                                                         continent = col_factor(),
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
                       preprints_used = recode_factor(preprints_used, `Not sure` = NA_character_),
                       preprints_used = fct_relevel(preprints_used, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       preprints_submitted = recode_factor(preprints_submitted, `Not sure` = NA_character_),
                       preprints_submitted = fct_relevel(preprints_submitted, c('No', 'Yes, once', 'Yes, a few times', 'Yes, many times')),
                       familiar = fct_relevel(familiar, c('Not familiar at all', 'Slightly familiar', 'Moderately familiar', 'Very familiar', 'Extremely familiar')),
                       acad_career_stage = fct_relevel(acad_career_stage, c('Grad Student', 'Post doc', 'Assist Prof', 'Assoc Prof', 'Full Prof'))) %>%
                mutate(hdi_level = fct_explicit_na(hdi_level, '(Missing)'),
                       familiar = fct_explicit_na(familiar, '(Missing)'),
                       discipline_collapsed = fct_explicit_na(discipline_collapsed, '(Missing)')) %>%
                mutate(missing_qs = rowSums(is.na(.)))

#### basic sample characteristics ####

# total sample who consented
nrow(all_survey_data)

#percentage of respondents who only consented
round(100*sum(all_survey_data$missing_qs == 54)/nrow(all_survey_data), 2)

#for those who answered 1 question, attrition rate
round(100 * sum(all_survey_data$missing_qs < 54 & all_survey_data$Progress != 100)/sum(all_survey_data$missing_qs < 54), 2)

#number who answered at least 1 question after consent
sum(all_survey_data$missing_qs < 54)


##create dataset of only those who answered at least 1 question for analysis
survey_data <- all_survey_data %>%
                  filter(missing_qs < 54)

# familiarity level of sample
survey_data %>% 
  group_by(familiar) %>% 
  tally()


100*sum(survey_data$familiar == 'Extremely familiar' | survey_data$familiar == 'Very familiar', na.rm = T)/nrow(survey_data) #percentage familiar
100*sum(survey_data$familiar == 'Not familiar at all', na.rm = T)/nrow(survey_data) #percentage unfamiliar

# favorability level of sample
survey_data %>% 
  group_by(favor_use) %>% 
  tally()

100*sum(survey_data$favor_use < 0, na.rm = T)/nrow(survey_data) #percentage unfavorable
100*sum(survey_data$favor_use == 0, na.rm = T)/nrow(survey_data) #percentage neutral
100*sum(survey_data$favor_use > 0, na.rm = T)/nrow(survey_data) #percentage favorable

# preprint usage/submission

# used or submitted
100* sum(survey_data$preprints_used == 'Yes, many times' | 
           survey_data$preprints_used == 'Yes, a few times' | 
           survey_data$preprints_submitted == 'Yes, many times' | 
           survey_data$preprints_submitted == 'Yes, a few times', na.rm = T)/nrow(survey_data)

# breakdown of submission rates
survey_data %>% 
  group_by(preprints_submitted) %>% 
  tally()

# percentage many/few submissions
100* sum(survey_data$preprints_submitted == 'Yes, many times' | survey_data$preprints_submitted == 'Yes, a few times', na.rm = T)/nrow(survey_data)

# breakdown of use rates
survey_data %>% 
  group_by(preprints_used) %>% 
  tally()

# percentage many/few usage
100* sum(survey_data$preprints_used == 'Yes, many times' | survey_data$preprints_used == 'Yes, a few times', na.rm = T)/nrow(survey_data)


# demographics #
survey_data %>% 
  group_by(acad_career_stage) %>% 
  tally()

# career level percentages
100*sum(survey_data$acad_career_stage == 'Grad Student' | survey_data$acad_career_stage == 'Post doc' , na.rm = T)/nrow(survey_data) #percentage grad/post docs
100*sum(grepl('Prof', survey_data$acad_career_stage))/nrow(survey_data) #percentage profs
100*sum(is.na(survey_data$acad_career_stage))/nrow(survey_data) #percentage didnt' answer/didn't fall into another category

# discipline percentages
survey_data %>% 
  group_by(bepress_tier1) %>%
  summarize(n = n(), percentage = 100*n/nrow(survey_data))

100*sum(survey_data$discipline_collapsed == 'Psychology', na.rm = T)/sum(survey_data$bepress_tier1 == 'Social and Behavioral Sciences', na.rm = T)

# country related variables
survey_data %>% 
  group_by(hdi_level) %>% 
  summarize(n = n(), percentage = 100*n/nrow(survey_data))

survey_data %>% 
  group_by(continent) %>% 
  summarize(n = n(), percentage = 100*n/nrow(survey_data)) %>%
  arrange(desc(n))

100*sum(survey_data$country == 'United States of America', na.rm = T)/nrow(survey_data)

# correlation favor-use/use/submissions and credibility questions
correlations1 <- survey_data %>%
  select(preprints_used, preprints_submitted, starts_with('preprint_cred')) %>%
  mutate(preprints_used = as.numeric(preprints_used),
         preprints_submitted = as.numeric(preprints_submitted)) %>%
  cor(use = 'pairwise.complete.obs', method = 'spearman')

correlations2 <- survey_data %>%
  select(favor_use, starts_with('preprint_cred')) %>%
  cor(use = 'pairwise.complete.obs')

correlations <- as.data.frame(cbind(correlations1[3:21, 1:2], correlations2[2:20, 1])) 

# median correlation magnitude
median(correlations %>%
         pivot_longer(names_to = 'corr_variable', cols = preprints_used:V3) %>%
         select(value) %>%
         mutate(value = abs(value)) %>%
         pull(value))

### cues by career/disicpline analyses ###

## by discipline analysis ##
discipline_q_means <- survey_data %>%
  select(-c(consent, HDI_2017)) %>%
  group_by(discipline_collapsed) %>%
  skim() %>%
  yank('numeric') %>%
  rename(question = skim_variable) %>%
  filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering' & discipline_collapsed != '(Missing)') %>%
  select(discipline_collapsed, question, mean) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean))

# largest diff between discipline wtihin question
discipline_q_means %>%
  group_by(question) %>%
  summarize(min = min(mean), max = max(mean)) %>%
  mutate(diff = max-min) %>%
  arrange(desc(diff)) %>%
  slice(1L)

# largest diff between question wtihin discipline
discipline_q_means %>%
  group_by(discipline_collapsed) %>%
  summarize(min = min(mean), max = max(mean)) %>%
  mutate(diff = max-min) %>%
  arrange(desc(diff)) %>%
  slice(1L)

# reformat data for lme models
credibility_data_long <- survey_data %>%
  dplyr::select(ResponseId, starts_with('preprint_cred'), discipline_collapsed, acad_career_stage) %>%
  drop_na() %>%
  pivot_longer(cols = starts_with('preprint_cred'), names_to = 'question', values_to = 'response') %>%
  mutate(question = as.factor(question))

## by discipline analysis ##
discipline_model <- lmer(response ~ discipline_collapsed + question + discipline_collapsed:question + (1|ResponseId), credibility_data_long %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'))
discipline_anova_output <- anova(discipline_model)

# R2 calculated using Edwards et al (2008) method
discipline_r2 <- ((discipline_anova_output[1,3])/discipline_anova_output[1,4] * discipline_anova_output[1,5])/(1 + ((discipline_anova_output[1,3])/discipline_anova_output[1,4] * discipline_anova_output[1,5]))
question_r2 <- ((discipline_anova_output[2,3])/discipline_anova_output[2,4] * discipline_anova_output[2,5])/(1 + ((discipline_anova_output[2,3])/discipline_anova_output[2,4] * discipline_anova_output[2,5]))


## by career_stage ##
career_q_means <- survey_data %>%
  select(-c(consent, HDI_2017)) %>%
  group_by(acad_career_stage) %>%
  skim() %>%
  yank('numeric') %>%
  rename(question = skim_variable) %>%
  select(acad_career_stage, question, mean) %>%
  filter(grepl('preprint', question)) %>%
  filter(!is.na(mean)) %>%
  mutate(mean = as.numeric(mean))

# largest diff between career stage wtihin question
career_q_means %>%
  group_by(question) %>%
  summarize(min = min(mean), max = max(mean)) %>%
  mutate(diff = max-min) %>%
  arrange(desc(diff)) %>%
  slice(1L)

# largest diff between question wtihin career stage
career_q_means %>%
  group_by(acad_career_stage) %>%
  summarize(min = min(mean), max = max(mean)) %>%
  mutate(diff = max-min) %>%
  arrange(desc(diff)) %>%
  slice(1L)

## by academic position analysis ##
position_model <- lmer(response ~ acad_career_stage + question + acad_career_stage:question + (1|ResponseId), credibility_data_long)
position_anova_output <- anova(position_model)

# R2 calculated using Edwards et al (2008) method
position_r2 <- ((position_anova_output[1,3])/position_anova_output[1,4] * position_anova_output[1,5])/(1 + ((position_anova_output[1,3])/position_anova_output[1,4] * position_anova_output[1,5]))
question_r2 <- ((position_anova_output[2,3])/position_anova_output[2,4] * position_anova_output[2,5])/(1 + ((position_anova_output[2,3])/position_anova_output[2,4] * position_anova_output[2,5]))



#### exploratory factor analysis ####

credibilty_qs <- survey_data %>%
  dplyr::select(ResponseId,starts_with('preprint_cred')) %>%
  column_to_rownames('ResponseId')

fa.parallel(credibilty_qs)

fa6 <- fa(credibilty_qs, nfactors = 6, rotate = 'oblimin') 
fa6
fa.diagram(fa6)

fa4 <- fa(credibilty_qs, nfactors = 4, rotate = 'oblimin') 
fa4
fa.diagram(fa4)

fa3 <- fa(credibilty_qs, nfactors = 3, rotate = 'oblimin') 
fa3
fa.diagram(fa3)

## measurement invariance calculations ##
base_model <- 'traditional =~ preprint_cred1_1 + preprint_cred1_2 + preprint_cred1_3	
               open_icons =~ preprint_cred4_1 + preprint_cred4_2 + preprint_cred4_3 + preprint_cred4_4	
               verifications =~ preprint_cred5_1 + preprint_cred5_2 + preprint_cred5_3	
               opinions =~ preprint_cred3_1 + preprint_cred3_2 + preprint_cred3_3	
               external_support    =~ preprint_cred1_4 + preprint_cred2_1	
               usage   =~ preprint_cred2_3 + preprint_cred2_4'

# by career stages testing
position_models <- cfa(model = base_model, data = survey_data, group = 'acad_career_stage')
summary(position_models, fit.measures = T)

measurementInvariance(model = base_model, data = survey_data, group = 'acad_career_stage')

# by discipline testing
discipline_models <- cfa(model = base_model, data = survey_data %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'), group = 'discipline_collapsed')
summary(discipline_models , fit.measures = T)

measurementInvariance(model = base_model, data = survey_data %>% filter(discipline_collapsed != 'Other' & discipline_collapsed != 'Engineering'), group = 'discipline_collapsed')


