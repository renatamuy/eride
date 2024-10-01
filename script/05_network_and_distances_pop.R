#distances and network
# Preparing population density raster
# *gravity model*

# Read population data

require(raster)

pop <- raster('D://OneDrive - Massey University//_env//human_population//worldpop//idn_pd_2020_1km_unconstrained_mercator_cubicspline.tif')

plot(pop)

# Get Pixel IDs

#p <- data.frame(rasterToPoints(pop))

# Project neighborhood graph (rook's case connectivity). 
#head(p)
colnames(p) <- c('x', 'y', 'pop_density')

nrow(p) #2273457

prepdf <- data.frame(na.omit(p))

nrow(prepdf)

dim(pop)[1]*dim(pop)[2]

# Export raw data prepdf for getis ord Gi* analysis

setwd(here())
dir.create('results')
setwd('results')
write.csv(prepdf, 'pop_density_indonesia.csv', row.names = F)

setwd(here())
setwd('results')

#p <- read.csv('prepdf.csv')

p$X <-NULL

coords <- cbind(p$x, p$y)

IDs <- row.names(p) # this is != from pixel ID in raster

length(IDs)

# Creating a list of neighbors for each location, using the k nearest neighbors 

#n = 25

# Takes a while to run

#The function returns a matrix with the indices of points belonging to the set of the 

# k (25) nearest neighbours of each other.

#knn <- spdep::knn2nb(spdep::knearneigh(coords, k = n, longlat = FALSE), row.names = IDs)

#knns <- include.self(knn)

#todo <- colnames(p)[3:ncol(p)]

#dfg <- data.frame(ID = IDs, x = p$x, y = p$y)

### Define the cutoff to only include neighbors within 300m.

# Adding cutoff
# dist_siminf <- SimInf::distance_matrix(x = p$x, y = p$y, cutoff = 50000)

library("distances")

set.seed(123)

# Fast!

# Toy data from 1:100

psub <- p[1:100,]

dist <- distances::distances(psub[, c(1,2)])

dim(dist)

nrow(p)

str(dist)

class(dist)

# Node 1
length(dist[1])

table(IDs == 999999)

summary(dist[1])
summary(dist[2273457]) #2273457 2mi

3633998 /1000

temp <- data.frame()

str(distance_matrix)

#---------------------------------------------------
# getting distance list
# All pixels distances to all pixels

for( i in 1:dim(dist)[2]){
  
  weights_link <- dist[i]
  o1 <- reshape2::melt(weights_link1)
  o1$from <- i
  o1$to <- row.names(o1)
  
  temp <- rbind(temp, o1)
  print(i)
  
}

# Tomorrow work on the resolution, because self distances are 928 m
#  928.1893    3   3

str(temp)
unique(temp$from)

temp$from <- as.character(temp$from )

g <- graph_from_data_frame(temp[,2:3], directed=TRUE)

g <- set_edge_attr(g, "weight", value= temp$value)

plot(g)

# Network with distances as weight

p$name <- row.names(p)

V(g)$pop_density <-  p[match(V(g)$name, p$name),"pop_density"] 

# require tidyverse
require(tidyverse)

p$pop_densityq <- cut(p$pop_density,
                      breaks = quantile(p$pop_density,
                                        probs = seq(0, 1, 0.25),
                                        na.rm = T),
                      include.lowest = T,
                      right = F)

table(p$pop_densityq, exclude = NULL)

# quantiles
V(g)$pop_densityq <-  p[match(V(g)$name, p$name),"pop_densityq"] 


V(g)$x = p[match(V(g)$name, p$name),"x"] 

V(g)$y=p[match(V(g)$name, p$name),"y"] 

V(g)$color=c( 'white', "turquoise2", 'yellow', "tomato")[as.numeric(V(g)$pop_densityq)]


# Spatial network with distances

l=matrix(c(V(g)$x, V(g)$y), ncol=2)

#regions=locations[match(V(g)$name, locations$Population),"Region"] 

E(g)$width <- E(g)$weight/10000 +0.01

# Remove loops

gnl <- igraph::simplify(g, remove.loops = T)

par(mar=c(2,2,2,2))

plot(gnl, layout=l, edge.arrow.size=.2, edge.curved=0,
     vertex.frame.color="#555555")

# Non-spatial plot

l <- layout_with_fr(gnl)

plot(gnl, layout=l)

l <- layout_in_circle(gnl)

plot(gnl, layout=l)

#  ------------------------------------