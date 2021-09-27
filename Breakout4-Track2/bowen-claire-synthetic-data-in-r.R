################################################################################
# Generating Synthetic Data for Data Privacy in R
################################################################################
# Claire McKay Bowen, cbowen@urban.org

# Load packages
library("tidyverse")

# Pre-processing data ---------------
dat <- starwars %>%           # loading the Star Wars data
     select(mass, species) %>%   # select the two variables we are interested
     drop_na() %>%               # simplifying the data to only complete variables
     .[-15, ] %>%                # Removed Jabba...because his mass was so high!
     mutate(species = 
                 factor(
                      ifelse(
                           species != "Human" & species != "Droid",
                           "Non-Human",
                           species)
                 )
     )

# Marginal Tables ---------------
# Number of observations
N <- nrow(dat)

# Calculate the number of observations in each
count_species <- dat %>% group_by(species) %>% count()
count_species
count_species$n / N

# Generating our synthetic data via sample()
set.seed(42)
syn_species <- sample(count_species$species,      # The possible observations
                      N,                          # The size of the synthetic data
                      replace = TRUE,             # With replacement
                      prob = count_species$n / N) # The weighted probabilities

# Synthetic data counts
syn_species %>% table()

# Synthetic data proportion
syn_species %>% table() %>% `/` (N)

# Probability Distributions ---------------
dat %>%
     select(mass) %>%
     as_tibble() %>%
     ggplot(data = ., aes(x = mass)) + 
     geom_histogram(binwidth = 20, 
                    fill = "white", 
                    color = "black") + 
     xlab("Mass (kg)") + ggtitle("Original Data")

# Sample Mean
mean_mass <- mean(dat$mass)
mean_mass

# Sample Standard Deviation
sd_mass <- sd(dat$mass)
sd_mass

# Generating our synthetic data via rnorm()
set.seed(22)
syn_mass <- rnorm(N, mean_mass, sd_mass) %>%
     as_tibble()

# Sample mean of the synthetic data
syn_mass %>% as_vector() %>% mean()

# Sample sd of the synthetic data
syn_mass %>% as_vector() %>% sd()

# Plot the results
ggplot(data = syn_mass, aes(x = value)) +
     geom_histogram(binwidth = 20, fill = "white", color = "black") +
     xlab("Mass (kg)") + ggtitle("Synthetic Data")

# Regression Model ---------------
# Applying lm()
mod_coef <- lm(mass ~ species, data = dat) %>%
     summary() %>%
     .$coefficients %>%
     .[, 1]

mod_coef
syn_species %>% table()

set.seed(42)
# Droid
droid_syndat <- mod_coef %>% # Coefficients from the linear model
     as_vector() %>%            # Convert to a vector
     `*` (c(1, 0, 0)) %>%       # Multiple and sum the coefficients for droid
     sum() %>% 
     `+` (rnorm(9, 0, 29.3))    # Add random noise per linear model assumption

# Human
human_syndat <- mod_coef %>% # Coefficients from the linear model
     as_vector() %>%            # Convert to a vector
     `*` (c(1, 1, 0)) %>%       # Multiple and sum the coefficients for human
     sum() %>% 
     `+` (rnorm(23, 0, 29.3))    # Add random noise per linear model assumption

# Non-Human
non_syndat <- mod_coef %>% # Coefficients from the linear model
     as_vector() %>%            # Convert to a vector
     `*` (c(1, 0, 1)) %>%       # Multiple and sum the coefficients for Non-Human
     sum() %>% 
     `+` (rnorm(25, 0, 29.3))    # Add random noise per linear model assumption)

mass_syndat <- c(droid_syndat, human_syndat, non_syndat)

mass_syndat %>% mean()
mass_syndat %>% sd()

ggplot(data = as_tibble(mass_syndat), aes(x = value)) + 
     geom_histogram(binwidth = 20, fill = "white", color = "black") + 
     xlab("Mass (kg)") + ggtitle("Synthetic Data")
