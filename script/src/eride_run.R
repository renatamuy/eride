eride_run <- function(rast, pop, nprocs = 7, memory = 1000, z = 0.2, radius = 10) {
  library(rgrass)
  
  start_time <- Sys.time()
  
  # Define window size
  window_size <- 2 * radius + 1
  
  # Binary image for forest areas based on land cover classes
  execGRASS("r.mapcalc",
            expression = "r = rast == 5 || rast == 6 || rast == 12 || rast == 13",
            flags = c("overwrite"))
  
  # Create null background
  execGRASS("r.mapcalc", flags = "overwrite",
            expression = "r_fragment_null = if(r == 1, 1, null())")
  
  # Create zero background
  execGRASS("r.mapcalc", flags = "overwrite",
            expression = "r_fragment_zero = if(r == 1, 1, 0)")
  
  # Identify individual patches
  execGRASS("r.clump", flags = c("d", "quiet", "overwrite"),
            input = "r_fragment_null", output = "r_fragment_id")
  
  # Count cells of patches
  execGRASS("r.stats.zonal", flags = c("overwrite"),
            base = "r_fragment_id", cover = "r_fragment_null",
            method = "count", output = "r_fragment_area_ncell")
  
  # Convert to biodiversity
  execGRASS("r.mapcalc",
            expression = paste0("bio = r_fragment_area_ncell^", z),
            flags = c("overwrite"))
  
  # Calculate latitude map
  execGRASS("r.mapcalc", flags = "overwrite",
            expression = "latitude = y() * r_fragment_zero")
  
  execGRASS("r.stats.zonal", flags = c("overwrite"),
            base = "r_fragment_id", cover = "latitude",
            method = "average", output = "latitude_scale_values")
  
  # Find patch edges
  execGRASS("r.neighbors", flags = c("c", "overwrite"),
            input = "r_fragment_zero", output = "r_range", size = 3,
            method = "range", nprocs = nprocs, memory = memory)
  
  # Create edges layer
  execGRASS("r.mapcalc",
            expression = "r_edges = r_range * r_fragment_zero",
            flags = c("overwrite"))
  
  # Create weighted boundaries
  execGRASS("r.mapcalc",
            expression = "wb = bio * r_edges",
            flags = c("overwrite"))
  
  # Calculate eRIDE using a gaussian weighted radius
  execGRASS("r.neighbors", flags = c("overwrite"),
            input = "wb", output = "eRIDE", size = window_size,
            weighting_function = "gaussian", weighting_factor = 2,
            method = "average", nprocs = nprocs, memory = memory)
  
  # Calculate Population at Risk (PAR)
  execGRASS("r.mapcalc",
            expression = "PAR = eRIDE * pop",
            flags = c("overwrite"))
  
  # Export results to GeoTIFF
  output_files <- list("fragments.tif" = "r_fragment_zero",
                       "areas.tif" = "r_fragment_area_ncell",
                       "latitude.tif" = "latitude",
                       "latitude_scales.tif" = "latitude_scale_values",
                       "biodiversity.tif" = "bio",
                       "edges.tif" = "r_edges",
                       "wb.tif" = "wb",
                       "eRIDE.tif" = "eRIDE",
                       "PAR.tif" = "PAR")
  
  for (file in names(output_files)) {
    execGRASS("r.out.gdal", input = output_files[[file]],
              output = file, format = "GTiff", type = "Float32",
              flags = c("overwrite", "f"),
              createopt = "TFW=YES,COMPRESS=DEFLATE,BIGTIFF=YES")
  }
  
  end_time <- Sys.time()
  print(paste("Execution time:", round(end_time - start_time, digits=2), " seconds."))
}
