# Libraries 
library(shiny)  
library(tidyr)
library(ggplot2)
library(dplyr)
library(shinydashboard)
library(writexl)

############################################################################
#                                                                          #
# Source R files from a folder - may be elsewhere - server                 #
# Anything that you can write as an R function (reactive or non-reactive)  #
# In my files : datamaker/cleaner                                          #
#                                                                          #
############################################################################
src_files <- list.files('R', full.names = TRUE)
for(source_file in c(src_files)){
  source(source_file, 
         local = TRUE)
}

######
# UI #
######
ui <- 
  fluidPage(
    # Title of application
    titlePanel(title = 'Customer Reviews'),
    # Create columns within rows, columns determined by width
    # Note the use of commas between elements
    # Input is variables from the ui
    # Output are placeholders for variables from the sever
    fluidRow(
      column(width = 3, 
             selectizeInput(inputId   = 'overlay', # Every input will have an Id variable
                            label     = 'Choose the plot overlay', # Label
                            choices   = c("Salesperson", 
                                          "Product", 
                                          "Type of Client"))), 
      # Need output here to show plot
      column(width = 9, 
             plotOutput(outputId = 'dot_plot'))
  )
)

##########
# SERVER #
##########    
server <- function(input, output, session){
  
  # Render plot creates the plot
  # the data is stored in the output variable
  # Note the ({ }) on functions in the server
  output$dot_plot <- renderPlot({

    ggplot(data = Flodger_paper_co, aes(x     = Salesperson,
                                        fill  = .data[[input$overlay]], #data masking  
                                        y     =  Review, 
                                        color = .data[[input$overlay]])) + 
      geom_dotplot(binaxis  = "y", 
                   stackdir = "center", 
                   dotsize  = 0.7)  + 
      theme_minimal() +
      theme(text = element_text(size = 20))
  })
}
shinyApp(ui, server)

# Simple app 

# library(shiny)
# 
# ui <- fluidPage(
#   "Hello, world!"
# )
# 
# server <- 
#   function(input, output, session){
#     #empty
#   }
# 
# shinyApp(ui, server)

