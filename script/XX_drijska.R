############################################################################
# building ---

# Link (flow) value is ~ 1 / (popdensity pixel x* pop density pixel y)

#Ideas for pandemic potential
# The link between pixels is the product of close neighborhood (25 closest neighbors) and immediate population density value
# Wilkinson approach: The link between pixels is the product of immediate neighborhood (4 closest neighbors) and immediate population density value,
# then pandemic potential from a to b the shortest path from a to b (summing all sources)
# The link between pixels is the product of shortest path between any two pixels and their accumulated population density values
# Node weights are == pop density
# So the pixels with hight PAR connected to large populations have the most influence to a pandemic


find_shortest_path <- function(raster_object, start_pixel_id, end_pixel_id) {
  # Convert the raster object to a distance matrix
  distance_matrix <- as.matrix(raster_object)
  
  # Create a graph object from the distance matrix
  graph <- graph.adjacency(distance_matrix, mode = "undirected", weighted = TRUE)
  
  # Find the shortest paths using Dijkstra's algorithm
  shortest_paths <- shortest_paths(graph, from = start_pixel_id, to = end_pixel_id, mode = "out")
  
  # Retrieve the shortest distance
  shortest_distance <- shortest_paths$dist[1]
  
  # Retrieve the shortest path
  shortest_path <- shortest_paths$path[[1]]
  
  return(list(distance = shortest_distance, path = shortest_path))
}

#The latter only works if the edge weights are non-negative.

spath <- shortest_paths(g, 1, 95, output = "both")

spath$vpath

spath$epath

# Apply Dijkstra's algorithm to get potential of pandemic spread from pixel x to pixel y

shortest_paths <- TBD

aux <- data.frame(xid = c(), yid = c(), received_risk=c())

for(i in pixels){
  
  received_risk_i <-sum(pop_at_risk_x*shortest_path_x_y)}

aux[i, 3] <- received_risk_i }

# donated risk

for(i in pixels){
  
  donated_risk_i <- pop_at_risk_x*sum(shortest_path_x_y)
  
}

# create raster from df
