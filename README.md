# climate-projections-narclim15

## Prerequisites

- [Climate Data Operators](https://code.mpimet.mpg.de/projects/cdo)
  - `brew install cdo`
- [R](https://r-project.org)

## Configuration

You can configure this project by checking the [`.Rprofile`](./.Rprofile). Options include:

* Telling R where `cdo` is. Use this if you get errors like `cdo: command not found` even though you've already installed `cdo`.
* Setting a timeout for downloads. The projections are big files, and R's default 1 minute timeout often isn't long enough to download them. In this project it's set to 1 hour by default, but you can increase it if you have particularly slow internet.
* Telling `{targets}` to use a different directory to store results and progress. By default it will create a `_targets/` folder in the project. If you need a different location (for example, an external drive with more space), you can set that location here.
  - You can also move an existing `_targets/` folder and update this option if you run out of space part way through the analysis.
  - Setting this option creates a `_targets.yaml` in the project folder.