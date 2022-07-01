library(tidyverse)
library(lubridate)


if(rstudioapi::isAvailable()){
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

# downloading .zip files about crime in the Czech Republic to ./src
seq.Date(
  from = as.Date("2019-01-01"), 
  to = today() %>% floor_date(unit = "month"),
  by = "months"
) %>%
  format("%Y%m") %>%
  paste0("https://kriminalita.policie.cz/api/v1/downloads/", . ,".csv.zip") %>%
  walk(
    .f = ~if(!file.exists(file.path("./src", basename(.x)))){
      curl_download(
        url = .x, 
        destfile = file.path("./src", basename(.x))
      )
    }
  )

# unzipping
dir("./src/", pattern = ".csv.zip", full.names = T) %>%
  walk(~unzip(.x, exdir = "./src"))

A_df_crime <- dir("./src/", pattern = "\\d{6}.csv$", full.names = T) %>%
  tail(1) %>%
  read_csv(col_types = "-dd-Tcc", col_names = c("lng", "lat", "datetime", "state", "types"),  skip = 1) %>%
  bind_rows() %>%
  rowwise() %>%
  mutate(types = str_split(types, ",") %>% unlist() %>% head(1)) %>% ungroup()

A_df_states_helper <- read_csv(
  "./src/states.csv",
  col_names = c("state", "state_label"),
  col_types = "cc",
  skip = 1
)

A_df_crime_types_helper <- read_csv(
  "./src/types.csv",
  col_names = c("types", "types_label"),
  col_types = "c--c",
  skip = 1
)


B_df <- left_join(A_df_crime, A_df_states_helper, by = "state") %>%
  left_join(A_df_crime_types_helper, by = "types") %>%
  select(-state, -types) %>%
  mutate(
    hour = hour(datetime) %>% as.character() %>% str_pad(width = 2, pad = "0"),
    date = floor_date(datetime, unit = "days") %>% as.Date(),
    count = 1
  ) %>%
  filter(date <= ymd("2022-06-05")) %>%
  filter(date >= ymd("2022-06-03"))


write_csv(file = "./data_clean/dat.csv", x = B_df)
