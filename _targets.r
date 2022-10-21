library(targets)

# source("R/01-download.r")

# tar_option_set(packages = c("readr", "dplyr", "ggplot2"))

# list(
#   tar_target(file, "data.csv", format = "file"),
#   tar_target(data, get_data(file)),
#   tar_target(model, fit_model(data)),
#   tar_target(plot, plot_model(model, data))
# )