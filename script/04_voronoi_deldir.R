
library(raster)
library(sp)
require(deldir)

# Step 1: Load a random greyscale image from the internet (choose one that has multiple zones of high contrast for optimal effect)
r <- raster("C:/Users/WILKINSON/Desktop/istockphoto-1362931590-612x612.jpg")
r <- raster("C:/Users/rdelaram/Desktop/random.tif")

# Step 2: Normalize the raster values to [0,1], and then exaggerate the image contrast with a power function
r_norm <- (r/256)^10
plot(r_norm)


# Step 3: Convert raster to a data frame to use as a probability surface
r_df <- as.data.frame(r_norm, xy=TRUE)  # I am not sure how scalable this will be for MASSIVE pictures
colnames(r_df) <- c("x", "y", "value")


# Step 4: Sample points based on raster values
# Lighter areas (higher raster values) will have higher probabilities
# When doing this with population data, you'll want more points around population centres, and fewer points in areas with low population.
num_points <- 100 # Change this to set the voronoi density
sampled_points <- r_df[sample(1:nrow(r_df), size = num_points, prob = r_df$value, replace = TRUE), c("x", "y")] 

# Step 5: Make voronois using deldir
original_voronoi <- deldir(sampled_points$x, sampled_points$y)

## Plot to see your original voronois.
## R plots do funny scaling things with overlays...
plot(r_norm)
points(sampled_points,add=T)
plot(original_voronoi, wlines="tess", col="blue",add=T)

# Step 6: MAKE IT FANCY.
# Use "Lloyd's algorithm" to rearrange the voronoi centroids until you end up with something pretty.
# You can change the number of iterations of the for loop... Three iterations seems good... 
#you can try more, but you'll end up smoothing out the arrangement of the voronois, and we want it to be roughly based around population density.

adjusted_points=sampled_points
for(x in 1:22){
  voronoi <- deldir(adjusted_points$x, adjusted_points$y)
  adjusted_points=tile.centroids(tile.list(voronoi))
}


final_voronoi=deldir(adjusted_points$x,adjusted_points$y)

#Plot the fancy voronois.
plot(r_norm)
plot(final_voronoi, wlines="tess", col="blue",add=T)
points(adjusted_points,col="red",add=T)
