# seed
set.seed(1)

# sample data 
sampler <- function(x, n = 100){
  sample(x, size = n, replace = TRUE)
}

# list of vars 
vars <- 
  list(
    'Salesperson'    = c('Dwigt', 'James', 'Stan', 'Bernie'), 
    'Product'        = c('Paper', 'Printer', 'Envelopes'), 
    'Type of Client' = c('Marquee', 'Regional', 'Local'), 
    'Review'         = runif(400, 0, 10)
  )

# Make the data frame
Flodger_paper_co <- 
 purrr::map_df(.x = vars, .f = sampler)

# prepping data
# Make factors levels - simple example for app 1
Flodger_paper_co$`Product`        <- factor(Flodger_paper_co$`Product`, 
                                        levels = c('Paper', 'Printer', 'Envelopes'))
Flodger_paper_co$`Type of Client` <- factor(Flodger_paper_co$`Type of Client`, 
                                        levels = c('Marquee', 'Regional', 'Local'))

writexl::write_xlsx(Flodger_paper_co, 
                    'Flodger_paper_co.xlsx')

# read data function 




