#' ----
# Packages used in Muylaert et al
#' ----

# extra 
library(ggplot2)
library(dplyr)
library(hrbrthemes)
require(RColorBrewer)
require(raster)


# package list
pkg_list_cran <- c("devtools", 
                   "here",
                   "tidyverse",
                   "xlsx", 
                   "data.table",
                   "janitor",
                   "stringi",
                   "reshape2",
                   "DataExplorer",
                   "skimr",
                   "rnaturalearth",
                   "rnaturalearthdata",
                   "spData",
                   "sf",
                   "raster",
                   "terra",
                   "ggmap",
                   "ggspatial",
                   "ggbump",
                   "gghighlight",
                   "ggraph",
                   "ggridges",
                   "igraph",
                   "maps",
                   "mapdata",
                   "legendMap",
                   "htmlwidgets",
                   "htmltools",
                   "lattice",
                   "ggpubr",
                   "graphlayouts",
                   "RColorBrewer",
                   "viridis",
                   "wesanderson",
                   "hrbrthemes")

# require else install all packages
lapply(X = pkg_list_cran, 
       FUN = function(x) if(!require(x, character.only = TRUE)) install.packages(x, dep = TRUE, quiet = TRUE))

# packages from github
if(!require(scico)) devtools::install_github("thomasp85/scico")
if(!require(platexpress)) devtools::install_github("raim/platexpress")
if(!require(Manu)) devtools::install_github("G-Thomson/Manu")


# end ---------------------------------------------------------------------