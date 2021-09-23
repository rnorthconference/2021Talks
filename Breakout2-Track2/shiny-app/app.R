#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

# Install Packages ----
library(shiny) # for shiny
library(bslib) # for shiny theme
library(ggplot2) # for visualization
library(tidyverse) # for manipulating data
library(DT) # for tables
library(fGarch) # for creating skewed distributions

sim_function <- function(num_sims = 10, num_ports = 1,
                         start_date = as.Date("2020-12-01"),
                         end_date   = as.Date("2021-03-01"),
                         vol_mean = 100, vol_var = 0.01,
                         oo_mean  = 14,   oo_var = 0.01,  oo_xi = 1.0,
                         od_mean  = 14,   od_var = 0.01,  od_xi = 1.0,
                         dw_mean  = 4,    dw_var = 0.01,  dw_xi = 1.0,
                         delay_range = c(), delay_mag = 0,
                         delay_range_2 = c(), delay_mag_2 = 0,
                         port_threshold = 100000) {

  # outer sim (multi instance)
  multi_instance_function <- data.frame(idx = integer(),
                                        dwhse_arrival_date = as.Date(character()),
                                        dwhse_volume = double()) 
  
  for (i in 1:num_sims) {
    
    # inner sim (single instance)
    date_range <- rep(seq.Date(from=as.Date("2020-12-01"),
                               to=as.Date("2021-03-01"), by="day"), num_ports)
    
    the_volume <- round(rnorm(length(date_range), vol_mean, vol_var), 0)
    order_oport <- round(rsnorm(length(date_range), mean = oo_mean, sd = oo_var, xi = oo_xi), 0)
    oport_dport <- round(rsnorm(length(date_range), mean = od_mean, sd = od_var, xi = od_xi), 0)
    trans_port <- order_oport + oport_dport
    
    port_data <- data.frame(date_range, the_volume, trans_port)
    port_data$port_arrival_date <- port_data$date_range + port_data$trans_port
    
    port_data$port_arrival_date <- as.Date(port_data$port_arrival_date, format="%Y-%m-%d")
    port_data$port_arrival_date <- if_else(as.character(port_data$port_arrival_date) %in% as.character(delay_range),
                                           port_data$port_arrival_date + delay_mag,
                                           port_data$port_arrival_date)
    
    # aggregate up port arrival data
    port_agg <- port_data %>% mutate(port_arrival_date = as.character(port_arrival_date)) %>%
      group_by(port_arrival_date) %>%
      summarise(port_arrival_volume = sum(the_volume))
    
    # meter port volume
    cap <- port_threshold
    port_agg$adjusted_port_volume <- port_agg$port_arrival_volume
    for (i in 1:(nrow(port_agg)-1)) {
      if (port_agg$adjusted_port_volume[i] > cap) {
        leftover <- port_agg$adjusted_port_volume[i] - cap
        leftover <- ifelse(leftover < 0, 0, leftover)
        port_agg$adjusted_port_volume[i] <- cap
        port_agg$adjusted_port_volume[i+1] <- port_agg$adjusted_port_volume[i+1] + leftover
      }
    } 
    
    port_agg$dport_dwhse <- round(rsnorm(length(port_agg$port_arrival_date), mean = dw_mean, sd = dw_var, xi = dw_xi))
    port_agg$dwhse_arrival_date <- as.Date(port_agg$port_arrival_date) + port_agg$dport_dwhse
    
    single_instance_agg <- port_agg %>%
      mutate(dwhse_arrival_date = as.character(dwhse_arrival_date)) %>%
      group_by(dwhse_arrival_date) %>%
      summarise(dwhse_volume = sum(adjusted_port_volume)) %>%
      mutate(dwhse_arrival_date = as.Date(dwhse_arrival_date)) %>%
      complete(dwhse_arrival_date = seq.Date(min(dwhse_arrival_date), max(dwhse_arrival_date), by="day")) %>%
      mutate(dwhse_volume = coalesce(dwhse_volume, 0))  
    
    multi_instance_function <- rbind(multi_instance_function, single_instance_agg)
    
  }
  
  print("the sim has run...")
  
  multi_instance_function <- multi_instance_function[multi_instance_function$dwhse_arrival_date > as.Date("2021-01-01") &
                                                       multi_instance_function$dwhse_arrival_date < as.Date("2021-04-01"),]
  
  return(multi_instance_function)

}

delay_range <- seq.Date(from=as.Date("2021-02-01"),
                        to=as.Date("2021-02-15"), by="day")

# Define UI ----
ui <- fluidPage(
  
  theme = bs_theme(version = 4, bootswatch = "yeti"), # https://bootswatch.com/
  
  # Application title
  titlePanel("Scenario Planning, with Data, on Steroids"),
  
  # * side bar ---- 
  sidebarLayout(
    sidebarPanel(
      
      # ** select penalty level ----
      selectInput("num_sims", label = p("Number of Instances"), 
                  choices = list("10" = 10, "50" = 50, "100" = 100), 
                  selected = 10),
      
      selectInput("num_ports", label = p("Number of Origin Ports"), 
                  choices = list("1" = 1, "10" = 10, "20" = 20), 
                  selected = 10),
      
      h2("Base Case"),
      hr(),

      numericInput("origin_volume_base", 
                   p("Daily Order Volume"), 
                   value = 100), 
      
      numericInput("volume_var_base", 
                   p("Daily Order Variance"), 
                   value = 0.01),      
      
      numericInput("delay_mag_base", 
                   p("Days of Delays"), 
                   value = 0),
      
      numericInput("transit_var_base", 
                   p("Transit Variance"), 
                   value = 0.01),
      
      numericInput("port_threshold_base", 
                   p("Port Throughput Max"), 
                   value = 100000), 
    
      h2("Alternative Scenario"),
      hr(),

      numericInput("origin_volume_comp", 
                   p("Daily Order Volume"), 
                   value = 100), 
      
      numericInput("volume_var_comp", 
                   p("Daily Order Variance"), 
                   value = 0.01),
            
      numericInput("delay_mag_comp", 
                   p("Days of Delay"), 
                   value = 0),

      numericInput("transit_var_comp", 
                   p("Transit Variance"), 
                   value = 0.01),
      
      numericInput("port_threshold_comp", 
                   p("Port Throughput Max"), 
                   value = 100000), 
    
      width = 4
      
    ),
    
    # * main panel ----
    mainPanel(
      
      # Output: Tabset w/ plot, summary, and table ----
      tabsetPanel(type = "tabs",
                  tabPanel("Single Instance", plotOutput("single_sim_box", height = "1000px")),
                  tabPanel("Scenario Comparison", plotOutput("scenario_plan_line", height = "1000px")))
    )
  )
)

# Define Server Logic ----
server <- function(input, output) {
  
  sim_data_base <- reactive({
    
    sim_function(num_sims      = input$num_sims,           num_ports      = input$num_ports,
                 delay_range   = delay_range,              delay_mag      = input$delay_mag_base,
                 delay_range_2 = delay_range_2,            delay_mag_2    = 0,
                 vol_mean      = input$origin_volume_base, vol_var        = input$volume_var_base,
                 oo_var        = input$transit_var_base,   od_var         = 0.01,
                 dw_var        = 0.01,                     port_threshold = input$port_threshold_base)
    
  })
  
  sim_agg_base <- reactive({
    
    d <- sim_data_base()
    prob_base_1250 <<- 1 - ecdf(d$dwhse_volume)(1250)
    d %>% group_by(dwhse_arrival_date) %>%
      summarise(arrival_volume = mean(dwhse_volume)) %>%
      mutate(sim = "base")
    
  })

  sim_data_comp <- reactive({

    sim_function(num_sims      = input$num_sims,           num_ports  = input$num_ports,
                 delay_range   = delay_range,              delay_mag = input$delay_mag_comp,
                 delay_range_2 = delay_range_2,            delay_mag_2 = 0,
                 vol_mean      = input$origin_volume_comp, vol_var = input$volume_var_comp,
                 oo_var        = input$transit_var_comp,   od_var = 0.01,
                 dw_var        = 0.01,                     port_threshold = input$port_threshold_comp)

  })

  sim_agg_comp <- reactive({

    sim_data_comp() %>% group_by(dwhse_arrival_date) %>%
      summarise(arrival_volume = mean(dwhse_volume)) %>%
      mutate(sim = "scenario")

  })

  sim_plan_comp <- reactive({

    uno <- sim_agg_base()
    dos <- sim_agg_comp()
    sim_plan_comp <- rbind(uno, dos)
    sim_plan_comp
    print(sim_plan_comp)
    
  })
  
  output$single_sim_box <- renderPlot({
    
    req(sim_data_base())
    d <- sim_data_base()
    
    # first, prepare the data for ribbon chart
    data_for_ribbon <- d %>%
      group_by(dwhse_arrival_date) %>%
      summarise(mean_count = mean(dwhse_volume),
                min_25_pct = quantile(dwhse_volume, 0.25),
                max_75_pct = quantile(dwhse_volume, 0.75)) %>%
      complete(dwhse_arrival_date = seq.Date(min(dwhse_arrival_date), max(dwhse_arrival_date), by="day")) %>%
      replace_na(list(mean_count = 0, min_25_pct = 0, max_25_pct = 0))
    
    # create ribbon chart using 25th and 75th percentiles as min and max (consider this your likely)
    ggplot(data_for_ribbon,
           aes(x = as.Date(dwhse_arrival_date), y = mean_count)) +
      geom_line() +
      theme_minimal() +
      geom_ribbon(aes(x = as.Date(dwhse_arrival_date), y = mean_count, ymin = min_25_pct, ymax = max_75_pct), alpha = 0.1) +
      labs(x = "Warehouse Arrival Date", y = "Warehouse Arrival Volume") +
      geom_hline(yintercept = 1000, color = "red") +
      annotate("rect", xmin = as.Date("2021-02-01"), xmax = as.Date("2021-02-15"),
                       ymin = 0, ymax = 2500,
                       alpha = .05) +
      scale_y_continuous(limits = c(0, 2500), breaks = seq(0, 2500, 100)) +
      scale_x_date(date_breaks = "1 week") +
      theme(axis.text=element_text(size=25),
            axis.title=element_text(size=30,face="bold"),
            axis.text.x = element_text(angle = 45, hjust = 1))

  })
  
  output$scenario_plan_line <- renderPlot({
    
    req(sim_plan_comp())
    d <- sim_plan_comp()
    
    print(head(d[d$dwhse_arrival_date > as.Date("2021-02-15"),],20))
    
    ggplot(d, aes(x=dwhse_arrival_date, y=arrival_volume, group=sim, color=sim)) +
      geom_line() +
      theme_minimal() +
      scale_color_manual(values=c("dodgerblue", "deeppink")) +
      scale_y_continuous(limits = c(0, 2500), breaks = seq(0, 2500, 100)) +
      scale_x_date(date_breaks = "1 week") +
      labs(x="Warehouse Arrival Date", y="Unit Arrival Volume", color ="Scenario") +
      theme(axis.text=element_text(size=25),
            axis.title=element_text(size=30,face="bold"),
            legend.title = element_text(size=25),
            legend.text = element_text(size=25),
            axis.text.x = element_text(angle = 45, hjust = 1)) +
      geom_hline(yintercept = 1000, color = "red") +
      annotate("rect", xmin = as.Date("2021-02-01"), xmax = as.Date("2021-02-15"),
               ymin = 0, ymax = 2500,
               alpha = .05)
    
  })
  
  output$prob_base_1250 <- renderText({
    d <- sim_data_base()
    1 - ecdf(d$dwhse_volume)(1250)
  })
  
}

# Run the application 
shinyApp(ui = ui, server = server)
