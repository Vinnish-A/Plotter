library(tidyverse)
library(VoronoiPlus)

rmse_safe <- function(tass) {
  w <- tass$values / sum(tass$values)
  a <- tass$areas
  sqrt(mean((a - w)^2))
}

resolve_speed_params <- function(speed = c("balanced", "fast", "quality"),
                                 iter_top = NULL,
                                 iter_sub = NULL,
                                 accuracy = NULL,
                                 centralize_steps = NULL,
                                 no_improve_patience = NULL) {
  speed <- match.arg(speed)
  defaults <- switch(
    speed,
    fast = list(iter_top = 40, iter_sub = 18, accuracy = 0.03, centralize_steps = 3, no_improve_patience = 6),
    balanced = list(iter_top = 90, iter_sub = 45, accuracy = 0.02, centralize_steps = 6, no_improve_patience = 10),
    quality = list(iter_top = 200, iter_sub = 120, accuracy = 0.01, centralize_steps = 10, no_improve_patience = 20)
  )

  list(
    iter_top = if (is.null(iter_top)) defaults$iter_top else iter_top,
    iter_sub = if (is.null(iter_sub)) defaults$iter_sub else iter_sub,
    accuracy = if (is.null(accuracy)) defaults$accuracy else accuracy,
    centralize_steps = if (is.null(centralize_steps)) defaults$centralize_steps else centralize_steps,
    no_improve_patience = if (is.null(no_improve_patience)) defaults$no_improve_patience else no_improve_patience
  )
}

voronoi_map_safe <- function(values, groups, shape, seed = NULL,
                             iter = 120, accuracy = 0.01,
                             centralize_steps = 10,
                             no_improve_patience = 20) {
  if (missing(shape)) {
    shape <- terra::buffer(
      terra::vect(cbind(0, 0), crs = "+proj=utm +zone=1"),
      1, 30
    )
  }
  if (is.null(seed)) {
    seed <- length(groups)
  }

  groups <- factor(groups, unique(groups))
  set.seed(seed)

  sites <- terra::spatSample(shape, length(groups))
  geom <- terra::crop(terra::voronoi(sites, bnd = shape), shape)

  res <- structure(
    list(
      geom = geom,
      sites = sites,
      areas = terra::expanse(geom) / sum(terra::expanse(geom)),
      groups = groups,
      values = values,
      shape = shape
    ),
    class = "voronoi_map"
  )

  for (i in seq_len(centralize_steps)) {
    res <- tryCatch(VoronoiPlus:::centralize(res), error = function(e) res)
  }

  if (iter > 0) {
    best_rmse <- rmse_safe(res)
    stagnant <- 0L
    for (i in seq_len(iter)) {
      candidate <- tryCatch(VoronoiPlus:::improve_weights(res), error = function(e) res)
      cand_rmse <- rmse_safe(candidate)
      if (cand_rmse <= best_rmse) {
        res <- candidate
        best_rmse <- cand_rmse
        stagnant <- 0L
      } else {
        stagnant <- stagnant + 1L
      }
      if (best_rmse < accuracy || stagnant >= no_improve_patience) {
        break
      }
    }
  }

  res
}

build_nested_voronoi <- function(data, top_col, sub_col, value_col,
                                 seed = 42, speed = "balanced",
                                 iter_top = NULL, iter_sub = NULL,
                                 accuracy = NULL,
                                 centralize_steps = NULL,
                                 no_improve_patience = NULL) {
  params <- resolve_speed_params(
    speed = speed,
    iter_top = iter_top,
    iter_sub = iter_sub,
    accuracy = accuracy,
    centralize_steps = centralize_steps,
    no_improve_patience = no_improve_patience
  )

  data <- data %>%
    transmute(
      top = as.character(.data[[top_col]]),
      sub = as.character(.data[[sub_col]]),
      value = as.numeric(.data[[value_col]])
    ) %>%
    filter(!is.na(top), !is.na(sub), is.finite(value), value > 0)

  top_weights <- data %>%
    group_by(top) %>%
    summarise(value = sum(value), .groups = "drop")

  top_map <- voronoi_map_safe(
    values = top_weights$value,
    groups = top_weights$top,
    seed = seed,
    iter = params$iter_top,
    accuracy = params$accuracy,
    centralize_steps = params$centralize_steps,
    no_improve_patience = params$no_improve_patience
  )

  top_poly <- get_polygons(top_map) %>%
    mutate(
      level = 1L,
      parent = "root",
      top_group = group,
      polygon_id = paste0("L1::", group, "::", geom)
    )

  root_poly <- as.data.frame(terra::geom(top_map$shape)) %>%
    dplyr::select(geom, x, y) %>%
    mutate(
      group = "root",
      value = sum(top_weights$value),
      level = 0L,
      parent = NA_character_,
      top_group = NA_character_,
      polygon_id = paste0("L0::root::", geom)
    )

  by_top_sub <- data %>%
    group_by(top, sub) %>%
    summarise(value = sum(value), .groups = "drop") %>%
    split(.$top)

  sub_polys <- vector("list", nrow(top_weights))
  for (i in seq_len(nrow(top_weights))) {
    cur_top <- top_weights$top[i]
    sub_weights <- by_top_sub[[cur_top]]

    sub_map <- voronoi_map_safe(
      values = sub_weights$value,
      groups = sub_weights$sub,
      shape = top_map$geom[i],
      seed = seed + i,
      iter = params$iter_sub,
      accuracy = params$accuracy,
      centralize_steps = params$centralize_steps,
      no_improve_patience = params$no_improve_patience
    )

    sub_polys[[i]] <- get_polygons(sub_map) %>%
      mutate(
        level = 2L,
        parent = cur_top,
        top_group = cur_top,
        polygon_id = paste0("L2::", parent, "::", group, "::", geom)
      )
  }

  bind_rows(root_poly, top_poly, bind_rows(sub_polys))
}

plot_nested_voronoi <- function(polygons, cols,
                                sub_border = "grey72",
                                top_border = "grey78",
                                outer_border = "grey78",
                                sub_linewidth = 0.45,
                                top_linewidth = 1.1,
                                outer_linewidth = 1.2,
                                bg = "grey92",
                                legend_title = NULL,
                                legend_text_size = 13,
                                legend_text_colour = "black",
                                legend_text_face = "plain",
                                legend_text_family = NULL,
                                legend_position = "right") {
  ggplot() +
    geom_polygon(
      data = polygons %>% filter(level == 0),
      aes(x = x, y = y, group = polygon_id),
      fill = NA,
      colour = outer_border,
      linewidth = outer_linewidth,
      linejoin = "round"
    ) +
    geom_polygon(
      data = polygons %>% filter(level == 2),
      aes(x = x, y = y, group = polygon_id, fill = top_group),
      colour = sub_border,
      linewidth = sub_linewidth,
      linejoin = "round"
    ) +
    geom_polygon(
      data = polygons %>% filter(level == 1),
      aes(x = x, y = y, group = polygon_id),
      fill = NA,
      colour = top_border,
      linewidth = top_linewidth,
      linejoin = "round"
    ) +
    coord_equal() +
    scale_fill_manual(values = cols, name = legend_title) +
    theme_void() +
    theme(
      legend.position = legend_position,
      legend.text = element_text(
        size = legend_text_size,
        colour = legend_text_colour,
        face = legend_text_face,
        family = legend_text_family
      ),
      plot.background = element_rect(fill = bg, colour = bg),
      panel.background = element_rect(fill = bg, colour = bg)
    )
}

make_voronoi_subject_plot <- function(raw_data,
                                      id_col = "Individual",
                                      top_col = "Phylum",
                                      value_col = "value",
                                      palette = default_phylum_palette(),
                                      seed = 42,
                                      speed = "balanced",
                                      iter_top = NULL,
                                      iter_sub = NULL,
                                      accuracy = NULL,
                                      centralize_steps = NULL,
                                      no_improve_patience = NULL) {
  data_long <- raw_data %>%
    pivot_longer(
      cols = -all_of(id_col),
      names_to = top_col,
      values_to = value_col
    )

  polys <- build_nested_voronoi(
    data = data_long,
    top_col = top_col,
    sub_col = id_col,
    value_col = value_col,
    seed = seed,
    speed = speed,
    iter_top = iter_top,
    iter_sub = iter_sub,
    accuracy = accuracy,
    centralize_steps = centralize_steps,
    no_improve_patience = no_improve_patience
  )

  p <- plot_nested_voronoi(polys, palette)
  list(plot = p, polygons = polys)
}

save_voronoi_plot <- function(plot_obj, path, width = 12, height = 10, dpi = 300) {
  ggplot2::ggsave(path, plot_obj, width = width, height = height, dpi = dpi)
}

geom_voronoi_nested <- function(data,
                                top_col,
                                sub_col,
                                value_col,
                                palette = default_phylum_palette(),
                                legend_title = NULL,
                                seed = 42,
                                speed = "balanced",
                                iter_top = NULL,
                                iter_sub = NULL,
                                accuracy = NULL,
                                centralize_steps = NULL,
                                no_improve_patience = NULL,
                                sub_border = "grey72",
                                top_border = "grey78",
                                outer_border = "grey78",
                                sub_linewidth = 0.45,
                                top_linewidth = 1.1,
                                outer_linewidth = 1.2,
                                add_fill_scale = TRUE) {
  polys <- build_nested_voronoi(
    data = data,
    top_col = top_col,
    sub_col = sub_col,
    value_col = value_col,
    seed = seed,
    speed = speed,
    iter_top = iter_top,
    iter_sub = iter_sub,
    accuracy = accuracy,
    centralize_steps = centralize_steps,
    no_improve_patience = no_improve_patience
  )

  layers <- list(
    geom_polygon(
      data = polys %>% filter(level == 0),
      aes(x = x, y = y, group = polygon_id),
      fill = NA,
      colour = outer_border,
      linewidth = outer_linewidth,
      linejoin = "round",
      inherit.aes = FALSE
    ),
    geom_polygon(
      data = polys %>% filter(level == 2),
      aes(x = x, y = y, group = polygon_id, fill = top_group),
      colour = sub_border,
      linewidth = sub_linewidth,
      linejoin = "round",
      inherit.aes = FALSE
    ),
    geom_polygon(
      data = polys %>% filter(level == 1),
      aes(x = x, y = y, group = polygon_id),
      fill = NA,
      colour = top_border,
      linewidth = top_linewidth,
      linejoin = "round",
      inherit.aes = FALSE
    )
  )

  if (isTRUE(add_fill_scale)) {
    layers <- c(layers, list(scale_fill_manual(values = palette, name = legend_title)))
  }

  layers
}
