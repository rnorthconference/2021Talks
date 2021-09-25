############################################################################
##                                                                        ##
## Examples of Miscellaneous Functions                                    ##
## UI Functions and Server Functions                                      ##
##                                                                        ##
############################################################################

############
#    UI    #
############
excel_input <-
  function(id) {
    fileInput(inputId  = id,
              label    = "Upload the customer reviews file",
              multiple = FALSE,
              accept   = c('.xls', '.xlsx'))
  }

overlay_input <- 
  function(id) {
    selectizeInput(inputId   = id, 
                   label     = 'Choose the plot overlay', 
                   choices   = NULL, 
                   width     = "80%")
  }

###############
#    SERVER   #
###############

# Functions that feed the server do not need to be reactive 
# Assumption is that user will make the required elements as reactive

# Function that just checks that the saleperson and reviews are contained in 
# the data

read_reviews <- 
  function(path,  
           check_cols = c('Review', 'Salesperson')){
    cols <- read_excel(path  = path, 
                       n_max = 0)
    
    if(!all(check_cols %in% names(cols))){
      stop("Some or all of the required columns are missing",
           call. = FALSE)
    }
    
    read_excel(path = path)
    
  }

###########################
#    EXAMPLE OF A MODULE  #
###########################
