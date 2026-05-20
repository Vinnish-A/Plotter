cran_packages <- c(
  "ggh4x",
  "legendry",
  "ggforce",
  "ggnewscale",
  "ggtext",
  "ggsignif"
)

missing <- cran_packages[!cran_packages %in% rownames(installed.packages())]
if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}
