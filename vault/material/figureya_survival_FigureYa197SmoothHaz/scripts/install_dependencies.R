# install_dependencies.R - Dependency installation script for FigureYa197SmoothHaz

cat("===========================================\n")
cat("Installing dependencies for FigureYa197SmoothHaz.Rmd\n")
cat("===========================================\n")

# Set CRAN mirror
options(repos = c(CRAN = "https://cloud.r-project.org/"))

# Check if package is installed
is_package_installed <- function(package_name) {
  package_name %in% rownames(installed.packages())
}

# Installation function
install_if_needed <- function(pkg) {
  if (!is_package_installed(pkg)) {
    cat("Installing:", pkg, "\n")
    tryCatch({
      install.packages(pkg, dependencies = TRUE, quiet = TRUE)
      cat("Successfully installed:", pkg, "\n")
    }, error = function(e) {
      cat("Installation failed:", pkg, "-", e$message, "\n")
    })
  } else {
    cat("Already installed:", pkg, "\n")
  }
}

# Install core packages
cat("Installing core packages...\n")
core_packages <- c(
  "cowplot", "dplyr", "ggplot2", "muhaz",
  "openxlsx", "survival", "survminer", "remotes",
  "Rttf2pt1", "extrafontdb"
)

for (pkg in core_packages) {
  install_if_needed(pkg)
}

# Special handling for extrafont
cat("Handling extrafont...\n")
if (!is_package_installed("extrafont")) {
  # Try installing from CRAN
  install_if_needed("extrafont")

  # If failed, try alternative methods
  if (!is_package_installed("extrafont")) {
    cat("Trying alternative method to install extrafont...\n")
    tryCatch({
      remotes::install_version("extrafont", version = "0.19")
    }, error = function(e) {
      cat("Version installation failed, trying GitHub installation...\n")
      remotes::install_github("wch/extrafont")
    })
  }
}

# Verify installation
cat("Verifying installation...\n")
required <- c("survival", "survminer", "muhaz", "ggplot2", "extrafont")
for (pkg in required) {
  if (is_package_installed(pkg)) {
    cat("OK:", pkg, "installed successfully\n")
  } else {
    cat("FAIL:", pkg, "installation failed\n")
  }
}

# Initialize fonts (if installed successfully)
if (is_package_installed("extrafont")) {
  cat("Initializing font system...\n")
  library(extrafont)
  tryCatch({
    # Import system fonts (Arial and Helvetica only)
    if (length(fonts()) == 0) {
      cat("Importing Arial and Helvetica fonts (may take a few minutes)...\n")
      font_import(prompt = FALSE)
    } else {
      # Import only Arial and Helvetica if fonts already exist
      cat("Importing Arial and Helvetica fonts...\n")
      font_import(pattern = "Arial", prompt = FALSE)
      font_import(pattern = "Helvetica", prompt = FALSE)
    }

    # Load fonts for PDF device
    loadfonts(device = "pdf", quiet = TRUE)

    # Verify fonts are registered
    cat("Available fonts:\n")
    print(fonttable()[fonttable()$FamilyName %in% c("Arial", "Helvetica"), ])

    cat("Font initialization completed\n")
  }, error = function(e) {
    cat("Font initialization failed:", e$message, "\n")
  })
}

cat("===========================================\n")
cat("Installation completed!\n")
cat("===========================================\n")
