# climate-projections-narclim15

These are projections of the annual number of days over temperature thresholds. Projections are based on [NARCliM1.5](https://doi.org/0.1029/2020EF001833).

The pipeline currently analyses bias-corrected daily maximum temperatures (`tasmax-bc`) from the 50 km CORDEX grid, which covers all of Australia, but it can easily configured to analyse other variables (eg. minimum temperatures) or to use the 10 km NARCliM1.5 grid, which covers south-eastern Australia.

## 📦 Prerequisites

- [Climate Data Operators](https://code.mpimet.mpg.de/projects/cdo)
  - `brew install cdo`
- [R](https://r-project.org)
- [GEOS]()
  - `brew install geos`
- (Optional, to download from NCI:) `libssh`
  - macOS: `brew install libssh`
  - `libssh-dev` on Debian/Ubuntu, `libssh-devl` on Fedora

## 🎛 Configuration

You can configure a few prerequisite options by checking the [`.Rprofile`](./.Rprofile). Options include:

* Telling R where `cdo` is. Use this if you get errors like `cdo: command not found` even though you've already installed `cdo`.
* Setting a timeout for downloads. The projections are big files, and R's default 1 minute timeout often isn't long enough to download them. In this project it's set to 1 hour by default, but you can increase it if you have particularly slow internet.
* Telling `{targets}` to use a different directory to store results and progress. By default it will create a `_targets/` folder in the project. If you need a different location (for example, an external drive with more space), you can set that location here.
  - You can also move an existing `_targets/` folder and update this option if you run out of space part way through the analysis.
  - Setting this option creates a `_targets.yaml` in the project folder.

You can further configure how the pipeline runs by altering the top half of `_targets.r`, marked by the comment `pipeline inputs`. These options include:

1. `data_sources`: where to get data from. Options include one or more of:

  - `dpie` to download collections from the [DPIE climate data portal](https://climatedata-beta.environment.nsw.gov.au) by their collection ID. Provide collection IDs using the `collections` option.
  - `nci` to download folders of files from NCI. In this case, `nci_host` is the name of either a remote host (eg. `user@gadi.nci.org.au`) or the name of a host block that matches [your SSH configuration]() (see below), and `nci_folders` lets you generate folders on NCI to download from based on the parameters you're interested in.
  - `manual` lets you manually provide files (if, for example, you've already downloaded some). In this case, `manual_folders` is a vector of paths to search. The files should still be named using the NARCliM DRS naming scheme:
    * `[var]_[grid]_[gcm]_[scenario]_[run]_[rcm]_v1_day_[startdate]-[enddate].nc`
    
2. `selected_thresholds`: a vector of temperature exceedance thresholds (in °C). The pipeline will count the number of days annually at or above each threshold.
3. `year_breaks`: a vector of dates used to split the days up. Values here are the dates themselves (given as YYYY-MM-DD strings); names are the labels to give to each period. Periods run forward from the date provided to the day before the next break: for example, if `1995` is `"1986-01-01"` and `-` is `"2006-01-01"`, files between 1986 and 2005 are given the period name `1995`. Use the name `-` to drop files in this period.
4. `yearblock_stats`: a vector of statistics to calculate over the period (for example, `"mean"` is the number of days ≥ X°C in an average year in the block, while `"max"` is the largest number of such days).
5. `model_ensemble_stats`: a vector of statistics to calculate across the different climate models (GCMs, RCMs and runs).
6. `boundaries`: `TODO - redescribe when switching to `{absmapsdata}`

### 🔐 Downloading data from NCI 

If you choose to have the pipeline automatically download data from NCI, you may wish to configure SSH externally using `~/.ssh/config`. This will allow you to use an SSH key, so that you aren't required to provide a password for each folder you download.

The host block in your configuration should be for a remote host that has access to `/g/data`, and the user should have access to the `at43` project, where NARCliM results are stored.

## 🌟 Running the pipeline

Once you're set up and have [changed any options](#configuration), running the pipeline is as as simple as running `./run.sh` or `./run.R`, which will call `targets::tar_make()`.

The pipeline will store intermediate results in the targets store folder, which by default is `_targets/` in the project folder. (You can [change this](#configuration) if you'd like.)

Final results are saved to the `data` folder.

You can run the pipeline again - say, adding new collections or temperature thresholds to `_targets.r` - and `{targets}` will just run the results that need updating.

## 🛠 Modifying and inspecting the pipeline

If you haven't used the `{targets}` package before, there are two main learning resources:

* [The {targets} R package user manual](https://books.ropensci.org/targets)
* [The {targets} website](https://docs.ropensci.org/targets)

The files you'll want to focus on are:

* `_targets.r` defines the pipeline: what steps will run, how they'll split and combine data up between steps, and what the essential inputs are (currently dataset collections and temperature thresholds).
* `R/*.r` files contain the code for each step. They are sourced when the pipeline first starts (most notably, creating the folders for intermediate results), and the functions are referred to in the pipeline in `_targets.r`.
* `run.R` and `.run.sh` are just shortcuts to run the pipeline, calling `targets::tar_make()`.
* `.Rprofile` sets other options: most notably the timeout for downloading files and, optionally, the locations of CDO and the targets data store.

The `{targets}` package has some other useful functions for understanding the pipeline, which you can run if you have an R session open in the project folder:

```r
# produce an interactive flowchart of the pipeline, its current status,
# and the number of branches at each step
targets::tar_visnetwork(targets_only = TRUE, label = "branches") 
```

## ❓ Help

If you find any problems with the data or our analysis, please feel free to [create an issue](https://github.com/360-info/climate-projections-narclim15)!
