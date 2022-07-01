library(leaflet)
library(leaflet.extras)
library(plotly)
library(reactable)
library(crosstalk)

if(rstudioapi::isAvailable()){
  setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
}

out0_dat_df <- readr::read_csv("./data_clean/dat.csv")

out0_dat <- highlight_key(out0_dat_df)

out1_filters <- list(
  # filter_slider("date", "Date and Time", out0_dat, ~date),
  # filter_select("select_all_helper", "Select All Helper", shared_data, ~select_all_helper),
  filter_slider("lng", "Longitude", out0_dat, ~lng, round = 2),
  filter_slider("lat", "Latitude", out0_dat, ~lat, round = 2),
  filter_select("types_label", "Crime Type", out0_dat, ~types_label, allLevels = F),
  filter_select("state_label", "Crime Status", out0_dat, ~state_label, allLevels = F),
  filter_select("hour", "Hour", out0_dat, ~hour)
)

out2_tbl <- out0_dat |>
  reactable(
    # selection = "multiple",
    # onClick = "select",
    groupBy = c("types_label", "state_label"), defaultPageSize = 10,
    theme = reactableTheme(
      borderColor = "#dfe2e5",
      stripedColor = "#f6f8fa",
      highlightColor = "#f0f5f9",
      cellPadding = "8px 12px",
      style = list(
        fontFamily = "-apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif"
      ),
      searchInputStyle = list(width = "100%")
    ),
    striped = T, highlight = T,
    columns = list(
      state_label = colDef(name = "Crime Status", minWidth = 200),
      types_label = colDef(name = "Crime Type", minWidth = 250),
      lng = colDef(name = "Longitude"),
      lat = colDef(name = "Latitude"),
      datetime = colDef(name = "Date and Time", minWidth = 130),
      count = colDef(
        "Crime Occurences",
        aggregate = "sum",
        footer = JS("function(colInfo) {
        let total = 0
        colInfo.data.forEach(function(row) {
          total += row[colInfo.column.id]
        })
        return total.toLocaleString('cs')
      }"),
        format = colFormat(separators = T)
      ),
      date = colDef(show = F),
      hour = colDef(show = F)
    )
  )

out3_map <- out0_dat |>
  # head(100) |>
  # select(lat, lng) |>
  leaflet() |>
  setView(lng = 15.5, lat = 50,zoom = 08) |>
  addTiles() |>
  addCircleMarkers(radius = 1, fill = F, fillOpacity = 0.99, group = ~state_label) |>
  addMarkers(
    clusterOptions = markerClusterOptions()
  )


out4_plotly <- out0_dat |>
  plot_ly(
    x = ~hour,
    y = ~count, 
    type = 'bar',
    transforms = list(
      list(
        type = 'aggregate',
        groups = ~hour,
        aggregations = list(
          list(
            target = 'y', func = 'sum', enabled = T
          )
        )
      )
    )
  ) %>%
  layout(
    title = 'Crime Rate During the Day',
    xaxis = list(title = 'Hour'),
    yaxis = list(title = 'Number of Incidents')
  )


out5_widgets <- htmltools::tagList(
  shiny::tags$h1("Crime in the Czech Republic from 2022-06-03 until 2022-06-05"),
  shiny::tags$br(),
  bscols(out1_filters, out2_tbl, widths = c(3, NA)),
  shiny::tags$br(), shiny::tags$br(), shiny::tags$br(),
  bscols(out3_map, out4_plotly, widths = c(6, 6)),
  shiny::tags$br(), shiny::tags$br(), shiny::tags$br()
)


# readr::write_lines(repr::repr_html(out5_widgets), file = "crosstalk_meetup.html")
# 
# browseURL(
#   file.path(getwd(), "crosstalk_meetup.html")
# )


