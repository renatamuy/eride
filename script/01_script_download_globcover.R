#' ----
#' script: download globe cover 2019
#' author: mauricio vancine
#' data: 2022-05-10
#' ----

# links
# https://glad.umd.edu/dataset/global-land-cover-land-use-v1
# https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/download.html

# prepare r ---------------------------------------------------------------

# packages
library(tidyverse)
library(sf)
library(terra)

# download time
options(timeout = 1e5)

# urls --------------------------------------------------------------------

# read urls
url_map <- readr::read_tsv("https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/map.txt", col_names = FALSE) %>% 
    dplyr::pull()
url_map

url_strata <- readr::read_tsv("https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/strata.txt", col_names = FALSE) %>% 
    dplyr::pull()
url_strata

# download ----------------------------------------------------------------

# map
dir.create("map")
purrr::map2(.x = url_map, .y = paste0("map/", basename(url_map)), .f = download.file, mode = "wb")

# strata
dir.create("strata")
purrr::map2(.x = url_strata, .y = paste0("strata/", basename(url_strata)), .f = download.file, mode = "wb")

# legend
download.file(url = "https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/legend.xlsx",
              destfile = "legend.xlsx", mode = "wb")

# grid --------------------------------------------------------------------

# files
files_map <- dir(path = "map", full.names = TRUE)
files_map    

# create
grid <- NULL

for(i in files_map){
    
    print(i)
    
    grid_i <- terra::rast(i) %>% 
        terra::ext() %>% 
        terra::as.polygons() %>% 
        sf::st_as_sf() %>% 
        dplyr::mutate(grid = sub(".tif", "", basename(i)))
        
    sf::st_crs(grid_i) <- "+proj=longlat +datum=WGS84 +no_defs"
    
    grid <- rbind(grid, grid_i)
    
}

grid
plot(grid$geometry)

# export
sf::st_write(grid, "grid.gpkg", append = FALSE)

# select ------------------------------------------------------------------

# extent
ext <- sf::st_bbox(c(xmin = 68.25, xmax = 141, ymin = -10.25, ymax = 53.5),
                   crs = st_crs(4326)) %>% 
    sf::st_as_sfc() %>% 
    sf::st_as_sf()
ext

plot(grid$geometry)
plot(ext$x, border = "red", add = TRUE)

# select
grid_ext <- grid[ext, ]
grid_ext

plot(grid$geometry)
plot(grid_ext, col = "blue", add = TRUE)
plot(ext$x, border = "red", add = TRUE)

# download selected -------------------------------------------------------

# read urls
url_map_sel <- readr::read_tsv("https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/map.txt", col_names = FALSE) %>% 
    dplyr::pull() %>% 
    grep(paste0(grid_ext$grid, collapse = "|"), ., value = TRUE)
url_map_sel

url_strata_sel <- readr::read_tsv("https://storage.googleapis.com/earthenginepartners-hansen/GLCLU_2019/strata.txt", col_names = FALSE) %>% 
    dplyr::pull() %>% 
    grep(paste0(grid_ext$grid, collapse = "|"), ., value = TRUE)
url_strata_sel

# map
dir.create("map")
purrr::map2(.x = url_map_sel, .y = paste0("map2/", basename(url_map_sel)), .f = download.file, mode = "wb")

# strata
dir.create("strata")
purrr::map2(.x = url_strata_sel, .y = paste0("strata/", basename(url_strata_sel)), .f = download.file, mode = "wb")

# end ---------------------------------------------------------------------
