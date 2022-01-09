pacman::p_load(tidyverse, readxl, lubridate, survival, survminer)

cov_list <- read_excel("./NFL_COVID_Transactions.xlsx")

cov_list_clean <- cov_list %>% 
  # Only COVID transactions
  filter(str_detect(Transaction, "COVID")) %>% 
  
  # Split into being placed on vs. taken off list
  mutate(Type = case_when(str_detect(Transaction, "Placed") ~ "On",
                          str_detect(Transaction, "Activated") ~ "Off",
                          TRUE ~ "Check This One")) %>% # Two odd ones, delete
  filter(Type %in% c("On", "Off")) %>% 
  
  # Fix one error with Josh Gordon
  mutate(Type = case_when(Player == "Josh Gordon (WR)" & Date == as.Date("2021-12-22") ~ "Off",
                          TRUE ~ Type))

cov_list_clean2 <- cov_list_clean %>% 
  # Clean hidden characters out of player names to get proper matching  
  mutate(Player = str_replace_all(Player, "[^[:alnum:]]", "")) %>% 
  mutate(all = 1) %>% 
  arrange(Player) %>% 
  group_by(Player) %>% 
  mutate(num_trans = cumsum(all)) %>% 
  ungroup() %>% 
  
  # Filter out a few duplicates/close contacts/false positives
  filter(!(Player %in% c("TylerHigbeeTE", "ChrisHarrisJrCB", "MikeWilliamsWR", "DavidJohnsonRB", "DarrylRobertsCB")) |
           Date >= as.Date("2021-12-17")) 

  
cov_list_clean3 <- cov_list_clean2 %>%
  select(Team, Player, Date, Type) %>% 
  mutate(Date = ymd(Date)) %>% 
  
  # Now that everyone has max 2 entries, pivot to wide data
  pivot_wider(names_from = Type, values_from = Date) %>%
  
  # Drop anyone who's been taken off without a corresponding put-on (likely from before Dec 1) 
  filter(!(is.na(On) & !is.na(Off))) %>% 
  
  mutate(off_date_known = 
           if_else(is.na(Off), 0, 1),
         Off = case_when(is.na(Off) ~ mdy("01-04-2022"),
                         TRUE ~ Off),
         Off_pre5dchange = case_when(On <= mdy("12-27-2021") & (is.na(Off) | Off > mdy("12-27-2021")) ~ mdy("12-27-2021"),
                                     TRUE ~ Off),
         off_date_known_pre5dchange = if_else(Off <= mdy("12-27-2021"), 1, 0),
         time_on_list = Off - On,
         time_on_list_pre5dchange = Off_pre5dchange - On,
         post_5day_change = case_when(Off >= mdy("12-28-2021") ~ "Yes",
                                      TRUE ~ "No")) %>% 
  
  filter(On >= mdy("12-16-2021"))



# How many actually got off list
sum(cov_list_clean3$off_date_known) #343 players off list
  

# Filter data before creating curves
cov_list_analysis <- cov_list_clean3 %>% 
  filter(Off_pre5dchange <= mdy("12-27-2021"))

#Create data for KM curves
rec_times <- survfit(with(cov_list_analysis, Surv(time_on_list_pre5dchange, off_date_known_pre5dchange == 1)) ~ 1)
#Surv() produces a list of survival or censoring times (e.g. 2, 4+, 3...)


#Plot KM curves
(ggsurv <- ggsurvplot(rec_times, 
                     data = cov_list_analysis, 
                     risk.table = TRUE,
                     fun = "event",
                     # linetype = "strata",
                     surv.scale = "percent",
                     risk.table.y.text.col = TRUE, #color risk table text annotation
                     risk.table.y.text = TRUE,
                     risk.table.fontsize = 4,
                     break.time.by = 1,
                     break.y.by = 0.25,
                     conf.int = FALSE,
                     # conf.int.style = "ribbon",
                     xlab = "Days on COVID List",
                     ylab = "% of Players on COVID List <= X Days",
                     # xlim = c(0,16),
                     legend = "none",
                     # legend.title = "",
                     # legend.labs = c("Ankle","Groin","Hamstring","Knee (non-ACL)", "Shoulder"),
                     # tables.theme = theme_survminer(),
                     ggtheme = theme_minimal(),
                     title = "Length of Time NFL Players on COVID List, 12/16-27/21",
                     caption = "Transactions data from sportsdata.usatoday.com. Excludes practice squads.",
                     tables.theme = theme(axis.ticks = element_blank(), 
                                          panel.grid = element_blank(),
                                          axis.text.x = element_blank(),
                                          axis.title.x = element_blank(),
                                          title = element_text(size = 10, face = "bold"))))

