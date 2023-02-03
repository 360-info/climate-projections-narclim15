#!/usr/bin/env Rscript

# This is a helper script to run the pipeline.
# Choose how to execute the pipeline below.
# See https://books.ropensci.org/targets/hpc.html
# to learn about your options.

# uncomment if you'd like to watch the build process with shiny as it runs
# targets::tar_watch(seconds = 10, outdated = FALSE, targets_only = TRUE,
#   label = "branches")

targets::tar_make()
# targets::tar_make_clustermq(workers = 2) # nolint
# targets::tar_make_future(workers = 2) # nolint
