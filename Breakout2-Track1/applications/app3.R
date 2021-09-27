# Options for storage
library(shiny)
library(tidyr)
library(ggplot2)
library(dplyr)
library(shinydashboard)
library(writexl)
library(readxl)

src_files <- list.files('R', full.names = TRUE)
for(source_file in c(src_files)){
  source(source_file, 
         local = TRUE)
}

# # # Set a color scheme from a css file
uui <-shinyUI(semanticPage(
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "bigdot-css.css")
    )
  )
)

######
# UI #
######
ui <- 
  dashboardPage(
    dashboardHeader(
      title = 'FLodger Paper Co.'
    ),
    dashboardSidebar(
      sidebarMenu(
        menuItem("Customer Reviews", 
                 tabName = 'reviews', 
                 icon    = icon('star'))
      )
    ),
    dashboardBody(
      uui,
      fluidRow(
        column(width = 3, 
               box(excel_input(id = 'data_file')),
               box(overlay_input(id = 'overlay'))),
        column(width = 9, 
               plotOutput(outputId = 'dot_plot'))
      )
    )
  )



server <- function(input, output, session){
  
  # determining the data path
  read_data <-
    reactive({
      req(input$data_file)
      read_excel(path = input$data_file$datapath)
    })
  
  observeEvent(read_data(), {
    select_cols <- setdiff(colnames(read_data()), 'Review')
    updateSelectizeInput(session = session,
                         inputId = 'overlay',
                         choices = select_cols)
  })
  
  observe({
    req(input$overlay)
    output$dot_plot <- renderPlot({
      ggplot(data = read_data(), 
             aes(x     = Salesperson, 
                 fill  = .data[[input$overlay]], 
                 y     = Review, 
                 color = .data[[input$overlay]])) + 
        geom_dotplot(binaxis  = "y", 
                     stackdir = "center", 
                     dotsize  = 0.7) + 
        theme_minimal() + 
        theme(text = element_text(size = 20))
      })
    })
}
shinyApp(ui, server)
