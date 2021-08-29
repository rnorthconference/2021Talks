library(dplyr)
library(fredr)

fred_function <- function(start_date, end_date){
  
  #Getting several different unemployment series
  df1 <- fredr(
    series_id = "UNRATE",
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)) %>% 
    mutate(series_id = " Total")
  
  df2 <- fredr(
    series_id = "LNS14000006",
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)) %>% 
    mutate(series_id = "Black/African American")
  
  df3 <- fredr(
    series_id = "LNS14000003",
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)) %>% 
    mutate(series_id = "White")
  
  df4 <- fredr(
    series_id = "LNS14000009",
    observation_start = as.Date(start_date),
    observation_end = as.Date(end_date)) %>% 
    mutate(series_id = "Hispanic/Latino")
  
  
  df <- rbind(df1, df2, df3, df4) %>%
    rename(Category = series_id,
           Date = date,
           UR = value) %>%
    select(-realtime_start, -realtime_end) %>%
    #Adding recession indicators
    mutate(recession = ifelse(Date >= '2020-02-01' | 
                                (Date >= '2007-12-01' & Date < '2009-07-01') | 
                                (Date >= '2001-03-01' & Date < '2001-12-01'), TRUE, FALSE),
           quarter_start = ifelse(substr(Date, 6, 7) %in% c('01','04','07','10'), TRUE, FALSE))
  
  write.csv(df, paste0("../data/fred_out_", end_date, ".csv"), row.names = FALSE)
  return(df)
  
}