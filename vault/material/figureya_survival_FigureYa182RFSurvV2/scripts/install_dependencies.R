#!/usr/bin/env Rscript
# Auto-generated R dependency installation script
# This script installs all required R packages for this project

# Set up mirrors for better download performance
options("repos" = c(CRAN = "https://cloud.r-project.org/"))
options(BioC_mirror = "https://bioconductor.org/")

# Function to check if a package is installed
is_package_installed <- function(package_name) {
  return(package_name %in% rownames(installed.packages()))
}

# Function to install CRAN packages
install_cran_package <- function(package_name) {
  if (!is_package_installed(package_name)) {
    cat("Installing CRAN package:", package_name, "\n")
    tryCatch({
      install.packages(package_name, dependencies = TRUE)
      cat("Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("Package already installed:", package_name, "\n")
  }
}

# Function to install Bioconductor packages
install_bioc_package <- function(package_name) {
  if (!is_package_installed(package_name)) {
    cat("Installing Bioconductor package:", package_name, "\n")
    tryCatch({
      if (!is_package_installed("BiocManager")) {
        install.packages("BiocManager")
      }
      BiocManager::install(package_name, update = FALSE, ask = FALSE)
      cat("Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("Package already installed:", package_name, "\n")
  }
}

# Function to install packages from source
install_from_source <- function(package_url) {
  cat("Installing package from source:", package_url, "\n")
  tryCatch({
    # Download the package source
    temp_file <- tempfile(fileext = ".tar.gz")
    download.file(package_url, temp_file, quiet = TRUE)
    
    # Install the package
    install.packages(temp_file, repos = NULL, type = "source")
    
    # Clean up
    unlink(temp_file)
    
    cat("Successfully installed package from source\n")
  }, error = function(e) {
    cat("Failed to install from source:", e$message, "\n")
  })
}

cat("Starting R package installation...\n")
cat("===========================================\n")

# Installing CRAN packages
cat("\nInstalling CRAN packages...\n")
cran_packages <- c("randomForestSRC", "survival")

for (pkg in cran_packages) {
  install_cran_package(pkg)
}

# Install randomSurvivalForest from source
cat("\nInstalling randomSurvivalForest from source...\n")
randomSurvivalForest_url <- "https://cran.r-project.org/src/contrib/Archive/randomSurvivalForest/randomSurvivalForest_3.6.4.tar.gz"
install_from_source(randomSurvivalForest_url)

cat("\n===========================================\n")
cat("Package installation completed!\n")
cat("You can now run your R scripts in this directory.\n")
