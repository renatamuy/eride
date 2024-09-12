create_cost_surface <- function(pop) {
  # Create a cost surface using the inverse of population density
  cost_surface <- 1 / pop
  
  # Replace any NaN or infinite values with a large cost 
  cost_surface[is.infinite(cost_surface)] <- maxValue(cost_surface) * 1000
  return(cost_surface)
}

cost_surface <- create_cost_surface(population)