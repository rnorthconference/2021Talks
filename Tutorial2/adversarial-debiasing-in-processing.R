# Uncomment and run the code below if you have not loaded the 
# library before (Step 2.5 in the instruction)

# library(aif360)
# reticulate::use_miniconda(condaenv = "r-test", required = TRUE)
# load_aif360_lib()


### Load the data 
original_data <- read.csv(
  "https://www.dropbox.com/s/ga8tr1glji7nrgk/adult_data_preprocessed.csv?dl=1"
)
original_data <- original_data[, -1]
head(original_data)

# Predict whether income exceeds $50K/yr based on census data.
# Variables:
## sex: 1 male, 0 female
## income binary: 1 > 50k, 0 <= 50k

# Protected Attribute Selection
# Protected Attribute: An attribute that partitions a population into groups 
# whose outcomes should have parity.
# Attribute `sex` is chosen as a protected attribute
protected_attribute <- "sex"

# Define Privileged and Unprivileged Groups
# Privileged Group: Group that has historically been at systematic advantage.
# Input required: List containing protected attribute name and value indicating 
# privileged group. 
# Sex is the protected attribute and value 1 indicates male. Together they form 
# privileged group.
privileged_groups <- list(protected_attribute, 1)

# Unprivileged Group: Group that has historically been at systematic 
# disadvantage.
# Input required: List containing protected attribute name and value indicating 
# unprivileged group. 
# Sex is the protected attribute and value 0 indicates female. Together they 
# form unprivileged group.
unprivileged_groups <- list(protected_attribute, 0)

# Convert the input dataframe into the aif360 format 
data_aif <- aif_dataset(data_path = original_data, 
                        favor_label = 1,         
                        unfavor_label = 0,       
                        privileged_protected_attribute = 1,
                        unprivileged_protected_attribute = 0,
                        target_column = "Income.Binary", 
                        protected_attribute = "sex")

# Let's split the data into train and test. 
# train should be 70% 
# test should be 30% 
set.seed(1234)
data_aif_split <- data_aif$split(num_or_size_splits = list(0.70))
data_aif_train <- data_aif_split[[1]]
data_aif_test  <- data_aif_split[[2]]

# We are concerned about the group fairness in this application. 
# Group Fairness: Partitions a population into groups defined by protected 
# attributes and seeks for some statistical measure to be equal across groups.

# We will use `Statistical Parity Difference` group fairness metric.
# It is computed as the difference of the rate of favorable outcomes received
# by the unprivileged group to the privileged group.
# This metric range from -1 to 1. The ideal value of this metric is 0, this 
# indicates that the privileged and unprivileged are selected at equal rates.
# A positive value indicates that the privileged group is at a disadvantage.
# A negative value indicates that the unprivileged group is at the disadvantage.
# An acceptable range for this metric is generally between -0.1 and 0.1. 
# However, what is deemed fair can vary based on the application.

# Initializing binary label dataset metric class
metric_train <- binary_label_dataset_metric(data_aif_train, 
                                            privileged_groups = privileged_groups, 
                                            unprivileged_groups = unprivileged_groups)
# Accessing `Statistical Parity Difference` metric
metric_train$statistical_parity_difference()

# Observe the metric result. If the value is between -0.1 and 0.1, privileged and 
# unprivileged groups are selected at similar rates and considered fair within
# the context of this application and no further action is required. 
# Metric value is -0.1932321 and indicates that unprivileged group is 
# at the disadvantage.

# Time to Mitigate the Bias
# In-processing Algorithm: Adversarial Debiasing
# Learns a classifier that maximizes prediction accuracy and simultaneously 
# reduces an adversary's (another network or second model) 
# ability to determine the protected attribute from the predictions. 
# This approach leads to a fair classifier as the predictions 
# cannot carry any group discrimination information that the adversary 
# can exploit.
sess <- tf$compat$v1$Session()

debiased_model <- adversarial_debiasing(privileged_groups = privileged_groups,
                                        unprivileged_groups = unprivileged_groups,
                                        scope_name = 'debiased_classifier',
                                        debias = TRUE,
                                        sess = sess)

debiased_model$fit(data_aif_train)

# predictions from the debiased 
data_aif_train_debiasing <- debiased_model$predict(data_aif_train)

# Initializing binary label dataset metric class for the debiased dataset
metric_train1 <- binary_label_dataset_metric(data_aif_train_debiasing, 
                                             privileged_groups = privileged_groups, 
                                             unprivileged_groups = unprivileged_groups)
# Accessing `Statistical Parity Difference` metric
# Observe the values based on the guidance provided above.
metric_train1$statistical_parity_difference()

