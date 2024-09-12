# raster simulations
# simulate a more aggregated raster
simulate_aggregated_raster <- function(nrows, ncols, value_range, filename, smooth = TRUE) {
  # Generate random values within the given range
  values <- runif(nrows * ncols, min = value_range[1], max = value_range[2])
  
  # Create the raster
  r <- raster(nrows = nrows, ncols = ncols, ext = extent(0, ncols, 0, nrows))
  r[] <- values
  
  if (smooth) {
    # Apply a focal filter for smoothing (e.g., Gaussian-like smoothing)
    # The weight matrix defines a smoother pattern, increasing aggregation
    w <- matrix(1, nrow = 5, ncol = 5)  # Larger matrix for more smoothing
    r <- focal(r, w = w, fun = mean, na.rm = TRUE)
  }
  
  # Save the raster to a file
  writeRaster(r, filename, overwrite = TRUE)
  
  return(r)
}


# simulate randomraster data
simulate_raster <- function(nrows, ncols, value_range, filename) {
  # Generate random values within the given range
  values <- runif(nrows * ncols, min = value_range[1], max = value_range[2])
  
  # Create the raster
  r <- raster(nrows = nrows, ncols = ncols, ext = extent_r)
  r[] <- values
  
  # Save the raster to a file
  writeRaster(r, filename, overwrite = TRUE)
  
  return(r)
}