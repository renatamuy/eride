# java zonal - gravity model

gc()
require(terra)
require(rgrass)
require(rnaturalearth)
require(sf)
require(ggplot2)
library(dplyr)
#devtools::install_github("G-Thomson/Manu")
library(Manu)
library(ggraph)
library(tidygraph)
library(maps)
library(sfnetworks)
library(ggspatial)

#--------------------------------------------------------------------------------------------

vector_file <- "C://Users//rdelaram//Documents//GitHub//eride/data//subset_districts.shp" 

#epsg 3857

regions <- read_sf(vector_file)
keep <- c("Banten" ,      "Jakarta",      "West Java" ,   "Central Java", "Yogyakarta" , "East Java" ,   "Bali"  )     
regions <- regions[regions$name_en %in% keep, ]

# be aware they are multi-polygon regions
centroids <- st_centroid(regions) # add pop raster 

# get raster of population at risk at the desired resolution
raster_data <- terra::rast("E://PAR_100.tif")

#plot(regions['name'])
#plot(raster_data, add=TRUE)


#raster_data_df <-  na.omit(as.data.frame(raster_data, xy = TRUE))

#
#ggplot() +
  #geom_tile(data = raster_data_df, aes(x = x, y = y, fill = PAR)) +  
 # geom_sf(data = regions, aes(color = name), fill= 'transparent',col="black", size=0.50) +  
 #  viridis::scale_fill_viridis(discrete = FALSE) +
  #labs(title = "") + 
  #theme_bw()


# zonal - average

regions$PAR <- terra::extract(raster_data, regions, fun = mean, na.rm = TRUE)

regionstoxp <- regions

regionstoxp$PAR <-  regions$PAR[[2]]

colnames(regionstoxp)

setwd('../results')

# Export to results (to merge with management)
st_write(regionstoxp, "regions_PAR.shp", append=FALSE)

# pairwise distances between centroids of regions
n_regions <- nrow(regions)

# create empty distance matrix
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

distance_matrix


# For zome bizarre sf reason, regions$PAR is actually a df within regions, so call PAR as
# and get the right row in the loop with slice

regions$PAR %>% dplyr::select(2) %>% dplyr::slice(j)

# or
regions$PAR[[2]][j]

regions$name


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
        Region_A = regions$name[i],  
        Region_B = regions$name[j],
        PAR_A = regions$PAR[[2]][i],  # Accessing the second column, i-th row
        PAR_B = regions$PAR[[2]][j],  # Accessing the second column, j-th row
        Distance = distance_matrix[i, j]  # Distance from distance_matrix
      ))
    }
  }
}

gravity_data

# Step 6: Apply the gravity model formula - define the constant G
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
write.csv(gravity_data, file = 'gravity_model_results.csv')

# Barchart with contributions

mypal <- c(rev(get_pal("Kereru")), 'cadetblue')

fig_grav <- ggplot(risk_contribution_long, aes(x = Name_A, y = Risk_Flow, fill = Name_B)) +
  geom_bar(stat = "identity", position = "stack") +
  labs(title = "Pandemic risk - Java Districts",
       x = "District",
       y = "Contributions to pandemic risk - Gravity Model",  fill = NULL) +
  theme_bw() +
  theme(axis.text.x = element_text(angle = 45, hjust = 1, size = 12), 
    axis.text.y = element_text(size = 12),                         
    axis.title.x = element_text(size = 14),                       
    axis.title.y = element_text(size = 14),                        
    plot.title = element_text(size = 16, hjust = 0.5) ) +
  scale_fill_manual(values = mypal) 

fig_grav

ggsave(filename= 'fig_contribution_grav_100m.tif', dpi=400, width=15, height = 17, units = 'cm')

ggsave(filename= 'fig_contribution_100m.png', dpi=400, width=15, height = 17, units = 'cm')


# Map with network

# Join the flow data with the centroid data using the appropriate column names
network_data <- risk_contribution_long %>%
  left_join(centroids, by = c("Name_A" = "name"))  # Join on 'Region' from df and 'name' from shapefile

# Create a simple edge list for flows
edge_list <- network_data %>%
  select(from = Name_A, to = Name_B, flow = Risk_Flow)

# Extract coordinates from the centroids shapefile
centroid_coords <- st_coordinates(centroids)

# Create a data frame for nodes that includes coordinates
coords_df <- data.frame(name = centroids$name, X = centroid_coords[, 1], Y = centroid_coords[, 2])

# Print the coordinates data frame to check its structure
print(head(coords_df))

# Create a data frame of unique nodes for the edge list and merge coordinates
nodes_df <- data.frame(name = unique(c(edge_list$from, edge_list$to)), stringsAsFactors = FALSE) %>%
  left_join(coords_df, by = "name")

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
  coord_fixed(1.3) +  
  xlim(103, 117) +    
  ylim(-9, -5) +      
  theme_minimal() +   
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
  left_join(nodes_df, by = c("from" = "name")) %>%
  rename(long.from = X, lat.from = Y) %>%
  left_join(nodes_df, by = c("to" = "name")) %>%
  rename(long.to = X, lat.to = Y) %>% 
  as_tibble()

# Final data wrangling

edges_sf <- edges_tbl %>%
  rowwise() %>%
  mutate(geometry = st_sfc(st_linestring(rbind(c(long.from, lat.from), c(long.to, lat.to))), crs = 4326)) %>%
  st_as_sf()


# Edges
st_write(edges_sf, "edges_sf.shp", delete_dsn = TRUE)


# Spatial network - gravity model http://127.0.0.1:17399/graphics/plot_zoom_png?width=2048&height=1090
require(ggrepel)

grav_network <- ggplot() +
  geom_polygon(data = indonesia_map, aes(x = long, y = lat, group = group), fill = "grey20") +
  coord_fixed(1.3) + 
  xlim(103, 117) +  
  ylim(-9, -5) +     
  theme_minimal() +  
    geom_curve(data = edges_sf, 
             aes(x = long.from, y = lat.from, xend = long.to, yend = lat.to, linewidth = 0.3*(flow) ), 
             curvature = 0.3, color = col.2, lineend = "round", alpha = 0.7, show.legend = FALSE) +
  #geom_text(data = nodes_df, aes(x = X, y = Y, label = name), color = 'white', hjust = -0.2, vjust = -0.2) +
  geom_label_repel(data = nodes_df, aes(x = X, y = Y, label = name), 
                   fill = "snow1",    # Background color for the tag
                   color = "gray40",   # Text color
                   size = 4, 
                   box.padding = 0.3, 
                   point.padding = 0.1, 
                   max.overlaps = 33) +
  geom_point(data = nodes_df, aes(x = X, y = Y), size = 4, color = col.1, alpha = 0.9) +
  scale_size_continuous(range = c(0.1, 3)) +  
  theme_void() +
  labs(title = "Pandemic Risk") +
  theme(plot.background = element_rect(fill = "azure2", color = NA)) #+
  #annotation_north_arrow(location = "tr", which_north = "true", style = north_arrow_fancy_orienteering) +
  #annotation_scale(location = "bl", width_hint = 0.5, unit_category = "metric", 
                  # style = "ticks", height = unit(0.3, "cm"), 
                  # plot_unit = c("km"), pad_x = unit(0.2, "cm")) #+  coord_sf(crs = 4326)

#---------------------------------------------------------------------------------------
grav_network

ggsave(filename= 'fig_3A.tif', dpi=400, width=18, height = 10, units = 'cm')
ggsave(filename= 'fig_3A.png', dpi=400, width=18, height = 10, units = 'cm')

#---------------------------------------------------------------------------------------------------------