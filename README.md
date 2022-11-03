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


## 🌟 Running the pipeline

Once you're set up and have [changed any options](#configuration), running the pipeline is as as simple as running `./run.sh` or `./run.R`, which will call `targets::tar_make()`.

The pipeline will store intermediate results in the targets store folder, which by default is `_targets/` in the project folder. (You can [change this](#configuration) if you'd like.)

Final results are saved to the `data` folder.

You can run the pipeline again - say, adding new collections or temperature thresholds to `_targets.r` - and `{targets}` will just run the results that need updating.

## 🎛 Configuration

You can configure a few prerequisite options by checking the [`.Rprofile`](./.Rprofile). Options include:

* Telling R where `cdo` is. Use this if you get errors like `cdo: command not found` even though you've already installed `cdo`.
* Setting a timeout for downloads. The projections are big files, and R's default 1 minute timeout often isn't long enough to download them. In this project it's set to 1 hour by default, but you can increase it if you have particularly slow internet.
* Telling `{targets}` to use a different directory to store results and progress. By default it will create a `_targets/` folder in the project. If you need a different location (for example, an external drive with more space), you can set that location here.
  - You can also move an existing `_targets/` folder and update this option if you run out of space part way through the analysis.
  - Setting this option creates a `_targets.yaml` in the project folder.

You can further configure how the pipeline runs by altering the top half of `-Targets.r`, marked by the comment `pipeline inputs`. These options include:

* Which source datasets to download from NSW DPIE (using the collection IDs)

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
