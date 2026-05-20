#!/usr/bin/env Rscript
# Auto-generated R dependency installation script
# This script installs required R packages for this project

# Set up mirrors for better download performance
options("repos" = c(CRAN = "https://cloud.r-project.org/"))

# Function to check if a package is installed
is_package_installed <- function(package_name) {
  return(package_name %in% rownames(installed.packages()))
}

# Function to install CRAN packages
install_cran_package <- function(package_name) {
  if (!is_package_installed(package_name)) {
    cat("Installing CRAN package:", package_name, "\n")
    tryCatch({
      install.packages(package_name, dependencies = TRUE, quiet = TRUE)
      cat("✓ Successfully installed:", package_name, "\n")
    }, error = function(e) {
      cat("✗ Failed to install", package_name, ":", e$message, "\n")
    })
  } else {
    cat("✓ Package already installed:", package_name, "\n")
  }
}

cat("Starting R package installation...\n")
cat("===========================================\n")

# 安装所需的CRAN包
cat("\nInstalling required CRAN packages...\n")
required_packages <- c("tidyverse", "ggplot2", "survival", "stringr", "viridis", "scales")

for (pkg in required_packages) {
  install_cran_package(pkg)
}

cat("\n===========================================\n")
cat("Package installation completed!\n")

# 验证安装
cat("\nVerifying package installation:\n")
all_installed <- TRUE
for (pkg in required_packages) {
  if (is_package_installed(pkg)) {
    cat("✓", pkg, "is installed\n")
  } else {
    cat("✗", pkg, "is NOT installed\n")
    all_installed <- FALSE
  }
}

# 测试包加载
cat("\nTesting package loading...\n")
test_packages <- function() {
  tryCatch({
    library(tidyverse)
    cat("✓ tidyverse loaded successfully\n")
  }, error = function(e) {
    cat("✗ tidyverse loading failed:", e$message, "\n")
  })
  
  tryCatch({
    library(ggplot2)
    cat("✓ ggplot2 loaded successfully\n")
  }, error = function(e) {
    cat("✗ ggplot2 loading failed:", e$message, "\n")
  })
  
  tryCatch({
    library(survival)
    cat("✓ survival loaded successfully\n")
  }, error = function(e) {
    cat("✗ survival loading failed:", e$message, "\n")
  })
  
  tryCatch({
    library(stringr)
    cat("✓ stringr loaded successfully\n")
  }, error = function(e) {
    cat("✗ stringr loading failed:", e$message, "\n")
  })
  
  tryCatch({
    library(viridis)
    cat("✓ viridis loaded successfully\n")
  }, error = function(e) {
    cat("✗ viridis loading failed:", e$message, "\n")
  })
  
  tryCatch({
    library(scales)
    cat("✓ scales loaded successfully\n")
  }, error = function(e) {
    cat("✗ scales loading failed:", e$message, "\n")
  })
}

cat("\nYou can now run your R scripts in this directory.\n")
