# Options for storage
library(shiny)
library(tidyr)
library(ggplot2)
library(dplyr)
library(shinydashboard)
library(writexl)
library(readxl)
library(shiny.semantic)


############################################################################
#                                                                          #
# Source R files from a folder                                             #
# Anything that you can write as an R function (reactive or non-reactive)  #
# In my files : datamaker/cleaner                                          #
#                                                                          #
############################################################################
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
               box(fileInput(inputId  = "data_file",
                             label    = "Upload the customer reviews file",
                             multiple = FALSE,
                             accept   = c('.xls', '.xlsx'))),
               box(selectizeInput(inputId   = 'overlay', 
                                  label     = 'Choose the plot overlay', 
                                  choices   = NULL, 
                                  width     = "80%"))),
        column(width = 9, 
               plotOutput(outputId = 'dot_plot'))
      )
    )
  )



server <- function(input, output, session){
  
  # determining the data path
  read_data <-
    reactive({
      # Require the data set to be present otherwise it stays as ""
      req(input$data_file)
      read_excel(path = input$data_file$datapath)
    })
  
  # observeEvent : I want the options to update if the data does
  observeEvent(read_data(), {
    
    # reactive functions uses ()
    select_cols <- setdiff(colnames(read_data()), 'Review')

    updateSelectizeInput(session = session,
                         inputId = 'overlay',
                         choices = select_cols)
  })
  
  ##############################################################################
  # Note the code for the dotplot runs slightly ahead of my input updates      #
  # This is because R Shiny  s IMPERATIVE programming, rather than declaritive #
  # That is, it's passive and reacts when it needs to                          #
  # The code ahead that updates the input doesn't run 'first'                  #
  # browser is a handy way to debug
  ##############################################################################
  
  # observe({
  #   req(input$overlay)
  #   Note : this is the same as if(input$overlay != ""){}
      # browser()
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
    # })
  }
shinyApp(ui, server)
