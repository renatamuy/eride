################################################################################
# Publication: Upscaling effects on infectious disease emergence risk emphasize 
# the need for local planning in primary prevention within biodiversity hotspots
# Script: java - gravity model - Voronoi vectorise
# Author: R. L. Muylaert
# Date: 2025
# R version 4.5.1
################################################################################

gc()
require(terra)
require(rgrass)
require(rnaturalearth)
require(sf)
require(ggplot2)
library(dplyr)
library(Manu)
library(ggraph)
library(tidygraph)
library(maps)
library(sfnetworks)
library(ggspatial)

#--------------------------------------------------------------------------------------------

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/results//districts_high_pop_voronoi_cat_forced.shp" 

#epsg 3857

regions <- read_sf(vector_file)

# be aware they are multi-polygon regions
centroids <- st_centroid(regions) # add pop raster 

unique(centroids$name_x)

# get raster of population at risk at the desired resolution
raster_data <- terra::rast("E://eride_scales_z0p20//PAR_100.tif")

# zonal - average
regions$PAR <- terra::extract(raster_data, regions, fun = mean, na.rm = TRUE)

regionstoxp <- regions

regionstoxp$PAR <- regions$PAR[[2]]

colnames(regionstoxp)

# Export to results (to merge with management)
st_write(regionstoxp, "regions_voronoi_forced_PAR.shp", append=FALSE)

# pairwise distances between centroids of regions
n_regions <- nrow(regions)

n_regions

# create empty matrix
distance_matrix <- matrix(NA, n_regions, n_regions)

# Geog distances
for (i in 1:n_regions) {
  for (j in 1:n_regions) {
    if (i != j) {
      # distance (km) between centroids
      distance_matrix[i, j] <- geosphere::distGeo(st_coordinates(centroids[i,]), st_coordinates(centroids[j,])) / 1000
    } else {
      distance_matrix[i, j] <- 0 # Distance to self is 0
    }
  }
}

distance_matrix # km

# For some sf reason, regions$PAR is actually a df within regions, so call PAR as
# and get the right row in the loop with slice

regions$PAR %>% dplyr::select(2) %>% dplyr::slice(j)

# or
regions$PAR[[2]][j]

regions$voronoi_id

gravity_data <- data.frame(Region_A = character(),
                           Region_B = character(),
                           PAR_A = numeric(),
                           PAR_B = numeric(),
                           Distance = numeric(),
                           stringsAsFactors = FALSE)


# Populate the dataframe with region pairs, their PARs (pop at risk), and distances
for (i in 1:n_regions) {
  for (j in 1:n_regions) {
    if (i != j) {  # Exclude self-pairs
      gravity_data <- rbind(gravity_data, data.frame(
        Region_A = regions$voronoi_id[i],  
        Region_B = regions$voronoi_id[j],
        PAR_A = regions$PAR[[2]][i],  # Accessing the second column, i-th row
        PAR_B = regions$PAR[[2]][j],  # Accessing the second column, j-th row
        Distance = distance_matrix[i, j]  # Distance from distance_matrix
      ))
    }
  }
}


head(gravity_data)

# Apply the gravity model formula - define the constant G
G <- 1

# Calculate trade flow using the gravity model formula
gravity_data$Risk_Flow <- G * (gravity_data$PAR_A * gravity_data$PAR_B) / gravity_data$Distance


# Check flow
hist(gravity_data$Risk_Flow)

cbind( gravity_data[1:2], round(gravity_data[3:ncol(gravity_data)], digits = 2))

# Contributions for risk

risk_contribution_long <- gravity_data %>%
  select(Region_A, Region_B, Risk_Flow) %>%
  rename(Name_B = Region_B, Name_A = Region_A)

# Summarize total risk contribution by region
total_risk_contribution <- risk_contribution_long %>%
  group_by(Name_A) %>%
  summarise(Total_Risk_Flow = sum(Risk_Flow)) %>%
  arrange(-Total_Risk_Flow) # Order by total contribution

# Update region levels based on total risk contribution

risk_contribution_long$Region <- factor(risk_contribution_long$Name_A,
                                        levels = total_risk_contribution$Name_A)

# Export
setwd('C://Users//rdelaram//Documents//GitHub//eride/results')

write.csv(gravity_data, file = 'gravity_model_voronoi_results.csv')

# Set up 69 colors


kpal <- c(rev(get_pal("Kereru")), 'cadetblue')

# Create a palette with 69 colors by interpolation
palheaps <- colorRampPalette(kpal)(n_regions)

# Barchart with contributions

fig_grav_voronoi <- ggplot(risk_contribution_long, aes(x = Name_A, y = Risk_Flow, fill = Name_B)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(title = "Pandemic risk - Java high-population Spatial Domain",
       x = "District",
       y = "Contributions to pandemic risk - Gravity Model",  fill = NULL) +
  theme_bw() +
  theme(legend.position = "bottom", axis.text.x = element_text(angle = 45, hjust = 1, size = 8), 
    axis.title.x = element_text(size = 12),
    axis.title.y = element_text(size = 12),  
    axis.text.y = element_text(size = 12), 
    plot.title = element_text(size = 12, hjust = 0.5) ) +
   scale_fill_manual(values = rev(palheaps) )  


fig_grav_voronoi

grav_network
setwd(here())
setwd('results/Figures')

ggsave(filename= 'Fig_S6B.tif', dpi=400, width=28, height = 25, units = 'cm')
ggsave(filename= 'Fig_S6B.png', dpi=400, width=28, height = 25, units = 'cm')


# Map with network

# Join the flow data with the centroid data using the appropriate column names
network_data <- risk_contribution_long %>%
  left_join(centroids, by = c("Name_A" = "voronoi_id"))  # Join on 'Region' from df and 'name' from shapefile

# Create a simple edge list for flows
edge_list <- network_data %>%
  select(from = Name_A, to = Name_B, flow = Risk_Flow)

# Extract coordinates from the centroids shapefile
centroid_coords <- st_coordinates(centroids)

# Create a data frame for nodes that includes coordinates
coords_df <- data.frame(voronoi_id = centroids$voronoi_id, X = centroid_coords[, 1], Y = centroid_coords[, 2])

# Print the coordinates data frame to check its structure
print(head(coords_df))

# Create a data frame of unique nodes for the edge list and merge coordinates
nodes_df <- data.frame(voronoi_id = unique(c(edge_list$from, edge_list$to)), stringsAsFactors = FALSE) %>%
  left_join(coords_df, by = "voronoi_id")

# this tbl_graph approach did not work... so I moved on to sfnetworks
graph_object <- tbl_graph(nodes = nodes_df, edges = edge_list)

#------------------ sfnetworks!

nodes_sf <- nodes_df %>% 
  as_tibble() %>% 
  st_as_sf(coords = c("X", "Y"), crs = 4326) 
  

plot(as_sfnetwork(nodes_sf))

#world_map <- map("world", regions = "Indonesia", col = "grey20", fill = TRUE, bg = "white", lwd = 0.1)

world_map <- map_data("world")

# Filter for Indonesia and Java
indonesia_map <- world_map %>%
  filter(region == "Indonesia")

# Create a ggplot map of Indonesia
ggplot() +
  geom_polygon(data = indonesia_map, aes(x = long, y = lat, group = group), fill = "grey70") +
  coord_fixed(1.3) +  # Adjust the aspect ratio
  xlim(103, 117) +    # Set x limits to zoom in on Java
  ylim(-9, -5) +      # Set y limits to zoom in on Java
  theme_minimal() +   # Minimal theme for cleaner look
  labs(title = "")


col.1 <- adjustcolor("orange red", alpha=0.4)
col.2 <- adjustcolor("orange", alpha=0.4)
edge.pal <- colorRampPalette(c(col.1, col.2), alpha = TRUE)
edge.col <- edge.pal(100)

plot(as_sfnetwork(nodes_sf), col=col.1)

#
ggplot() +
  geom_polygon(data = indonesia_map, aes(x = long, y = lat, group = group), fill = "grey20") +
  geom_sf(data = st_as_sf(nodes_sf), color = col.1, size = 3) +  # Plot nodes
  coord_sf(xlim = c(103, 117), ylim = c(-9, -5)) +  # Adjust to focus on Java
  theme_minimal() +
  labs(title = "Network over Java Island")


# Step 2: Create an sfnetwork object from the edge_list and nodes_sf
# Convert edge_list to a tibble for better compatibility
edges_tbl <- edge_list %>%
  mutate(from = as.character(from), to = as.character(to))


edges_tbl <- edge_list %>%
  left_join(nodes_df, by = c("from" = "voronoi_id")) %>%
  rename(long.from = X, lat.from = Y) %>%
  left_join(nodes_df, by = c("to" = "voronoi_id")) %>%
  rename(long.to = X, lat.to = Y) %>% 
  as_tibble()

# Final data wrangling

edges_sf <- edges_tbl %>%
  rowwise() %>%
  mutate(geometry = st_sfc(st_linestring(rbind(c(long.from, lat.from), c(long.to, lat.to))), crs = 4326)) %>%
  st_as_sf()


# Edges
grav_network
setwd(here())
setwd('results')

st_write(edges_sf, "edges_sf_voronoi.shp", delete_dsn = TRUE)


# Spatial network - gravity modelhttp://127.0.0.1:17399/graphics/plot_zoom_png?width=2048&height=1090

grav_network <- ggplot() +
  geom_polygon(data = indonesia_map, aes(x = long, y = lat, group = group), fill = "grey20") +
  coord_fixed(1.3) + 
  xlim(103, 117) +  
  ylim(-9, -5) +     
  theme_minimal() +  
    geom_curve(data = edges_sf, 
             aes(x = long.from, y = lat.from, xend = long.to, yend = lat.to, linewidth = 0.3*sqrt(flow) ), 
             curvature = 0.3, color = col.2, lineend = "round", alpha = 0.7, show.legend = FALSE) +
  geom_text(data = nodes_df, aes(x = X, y = Y, label = voronoi_id), color = 'white', hjust = -0.2, vjust = -0.2) +
  geom_point(data = nodes_df, aes(x = X, y = Y), size = 4, color = col.1, alpha = 0.9) +
  scale_size_continuous(range = c(0.1, 3)) +  
  theme_void() +
  labs(title = "Pandemic Risk") +
  theme(plot.background = element_rect(fill = "azure2", color = NA)) #+
  #annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
  #annotation_scale(location = "bl", width_hint = 0.5, unit_category = "metric", 
                  # style = "ticks", height = unit(0.3, "cm"), 
                  # plot_unit = c("km"), pad_x = unit(0.2, "cm")) #+  coord_sf(crs = 4326)

grav_network

# Too many edges, so let's get the top ones
grav_network

# Getting just the top links

top_edges_sf <- edges_sf %>%
  filter(flow > 15)     

table(top_edges_sf$flow > 15)
nrow(top_edges_sf)
unique(top_edges_sf$from)

top_nodes_sf <- nodes_df[nodes_df$voronoi_id %in% top_edges_sf$from,]

nrow(top_nodes_sf) #33


# Fig top flows
require(ggrepel)
grav_network_top <- ggplot() +
  geom_polygon(data = indonesia_map, aes(x = long, y = lat, group = group), fill = "grey20") +
  coord_fixed(1.3) + 
  xlim(103, 117) +  
  ylim(-9, -5) +     
  theme_minimal() +  
  geom_curve(data = top_edges_sf,  
             aes(x = long.from, y = lat.from, xend = long.to, yend = lat.to, linewidth = 0.3*(flow)), 
             curvature = 0.3, color = col.2, lineend = "round", alpha = 0.7, show.legend = FALSE) +
  geom_label_repel(data = top_nodes_sf, aes(x = X, y = Y, label = voronoi_id), 
                   fill = "snow1",    # Background color for the tag
                   color = "gray40",   # Text color
                   size = 2, 
                   box.padding = 0.5, 
                   point.padding = 0.3, 
                   max.overlaps = 33) +
  geom_point(data = top_nodes_sf, aes(x = X, y = Y), size = 2, color = col.1, alpha = 0.9) +
  scale_size_continuous(range = c(0.1, 3)) +  
  theme_void() +
  labs(title = "") +
  theme(plot.background = element_rect(fill = "azure2", color = NA))

grav_network_top 

setwd(here())
setwd('results/Figures')

# export fig_grav_network_100m_voronoi_15plus
ggsave(filename= 'Fig_04B.tif', dpi=400, width=18, height = 10, units = 'cm')
ggsave(filename= 'Fig_04B.png', dpi=400, width=18, height = 10, units = 'cm')
#---------------------------------------------------------------------------------------------------------