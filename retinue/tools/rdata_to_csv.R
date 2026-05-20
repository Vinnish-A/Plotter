args <- commandArgs(trailingOnly = TRUE)
if (length(args) < 2) {
  stop("usage: Rscript rdata_to_csv.R <input> <output_dir>")
}

input <- normalizePath(args[[1]], mustWork = TRUE)
output_dir <- args[[2]]
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

safe_name <- function(x) {
  x <- gsub("[^A-Za-z0-9_.-]+", "_", x)
  x <- gsub("^_+|_+$", "", x)
  if (identical(x, "")) "object" else x
}

write_object <- function(name, value) {
  out <- file.path(output_dir, paste0(safe_name(name), ".csv"))
  if (is.data.frame(value)) {
    utils::write.csv(value, out, row.names = FALSE, na = "")
    return(out)
  }
  if (is.matrix(value) || is.table(value)) {
    utils::write.csv(as.data.frame(value), out, row.names = FALSE, na = "")
    return(out)
  }
  if (is.atomic(value) && length(value) > 0) {
    utils::write.csv(data.frame(value = value), out, row.names = FALSE, na = "")
    return(out)
  }
  NULL
}

written <- character()
summary_rows <- data.frame(object = character(), class = character(), length = integer())
ext <- tolower(tools::file_ext(input))

if (ext == "rds") {
  value <- readRDS(input)
  result <- write_object(tools::file_path_sans_ext(basename(input)), value)
  if (!is.null(result)) written <- c(written, result)
} else {
  env <- new.env(parent = emptyenv())
  loaded <- load(input, envir = env)
  for (name in loaded) {
    value <- get(name, envir = env)
    summary_rows <- rbind(
      summary_rows,
      data.frame(object = name, class = paste(class(value), collapse = "|"), length = length(value))
    )
    result <- write_object(name, value)
    if (!is.null(result)) written <- c(written, result)
  }
}

if (length(written) == 0) {
  out <- file.path(output_dir, "object_summary.csv")
  if (nrow(summary_rows) == 0) {
    summary_rows <- data.frame(object = basename(input), class = "unknown", length = 0)
  }
  utils::write.csv(summary_rows, out, row.names = FALSE, na = "")
  written <- c(written, out)
}

manifest <- file.path(output_dir, "_rdata_conversion_manifest.csv")
utils::write.csv(
  data.frame(source = rep(input, length(written)), csv = written),
  manifest,
  row.names = FALSE,
  na = ""
)
