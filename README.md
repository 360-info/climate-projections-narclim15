# climate-projections-narclim15



## Prerequisities

- [Climate Data Operators](https://code.mpimet.mpg.de/projects/cdo)
  - `brew install cdo`
- [R](https://r-project.org)


### To set an external folder

This pipeline will, by default, create a `_targets` folder in the project to download and analyse the climate data. This requires several hundred GB of free space.

If you'd prefer to have this folder created elsewhere, run the following to set a different path (for example, a folder on a high-performance external drive):

```r
targets::tar_config_set(store = "/my/scratch/path")
```

This will create a `_targets.yaml` in your project directory (we do not version control this file, since the path is particular to your system).
