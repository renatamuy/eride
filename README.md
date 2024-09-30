[![Typing SVG](https://readme-typing-svg.herokuapp.com?color=%2336BCF7&center=true&vCenter=true&width=600&lines=Kia+ora!;Let's+do+this;We+love+R)](https://git.io/typing-svg)

# eride tasks
 
# 29/09/2023

* Dealing with storage: 10TB HD :white_check_mark:
* Compression type set to Float32 :white_check_mark:
* Code average latitude per patch :white_check_mark:
* Weird values from code (class code from map == detailed color legend is different from class code for strata), re-run :white_check_mark:
* Projected birds and mammals AOH of the world layer (100 m) :white_check_mark:

# 11/10/2023

* Mosaic of the world (globcover) running

# Nov 2024
* Mosaic job failed.

# July-August 2024
* Code trim :soon:
* Meeting with Dave W :soon:

# September 2024

* Reproject any big raster 🗺️ in R grass when importing :white_check_mark:
* Set up code for any region and at any scale :white_check_mark:
* Run for thw world :soon:
* Creating the mosaic of tropics and subtropics area :soon:
* Adjust code for latitudinal gradients of biodiversity by setting up a decay function from the Equator and limiting maximum values of Biodiversity :soon:

**Draft**: [Click here](https://docs.google.com/document/d/1XA9YiusEpzN-8HhapnUwRKm7G4IbV6cg4AtUOdaiaGg/edit?usp=sharing)


# Gravity Model Maths

## 1. Define the Set of Provinces to Keep

Let \( K \) be the set of provinces to retain:

\[
K = \{\text{Banten},\ \text{West Java},\ \text{Central Java},\ \text{Yogyakarta},\ \text{East Java},\ \text{Bali}\}
\]

## 2. Read Spatial Data and Calculate Centroids

For each region \( i \) in \( K \), determine its centroid \( C_i \):

\[
C_i = \text{Centroid of region } i
\]

## 3. Extract Mean Raster Values of Population at Risk (PAR) for Each Region

Calculate the mean raster value for each region \( i \):

\[
\text{PAR}_i = \frac{1}{N_i} \sum_{k=1}^{N_i} \text{Raster}(k)
\]

Where:
- \( N_i \) is the number of raster cells in region \( i \).
- \( \text{Raster}(k) \) represents the raster value of the \( k \)-th cell in region \( i \).

## 4. Calculate Pairwise Distances Between Polygon Centroids

Compute the geographic distance \( D_{ij} \) between the centroids of regions \( i \) and \( j \):

\[
D_{ij} =
\begin{cases}
0 & \text{if } i = j \\
\frac{\text{distGeo}(C_i, C_j)}{1000} & \text{if } i \neq j
\end{cases}
\]

Where:
- \( \text{distGeo}(C_i, C_j) \) calculates the geographic distance in meters between centroids \( C_i \) and \( C_j \).
- Dividing by 1000 converts the distance to kilometers.

## 5. Create Pairwise Region Interactions Data Frame

Construct a data frame \( \text{Gravity\_Data} \) containing all unique pairs of regions with their corresponding PAR values and distances:

\[
\text{Gravity\_Data} = \left\{ 
\left( 
\text{Region}_A, \text{Region}_B, \text{PAR}_A, \text{PAR}_B, D_{AB} 
\right) \ \bigg| \ \text{Region}_A, \text{Region}_B \in K,\ \text{Region}_A \neq \text{Region}_B 
\right\}
\]

## 6. Apply the Gravity Model

The gravity model estimates the risk flow \( \text{Risk\_Flow}_{ij} \) between regions \( i \) and \( j \) as:

\[
\text{Risk\_Flow}_{ij} = G \times \frac{\text{PAR}_i \times \text{PAR}_j}{D_{ij}}
\]

Where:
- \( G \) is a constant (e.g., \( G = 1 \)).
- \( \text{PAR}_i \) and \( \text{PAR}_j \) are the mean raster values for regions \( i \) and \( j \), respectively.
- \( D_{ij} \) is the distance between the centroids of regions \( i \) and \( j \).

## 7. Summary of the Gravity Model

Combining the above steps, the gravity model can be summarized as:

\[
\text{Risk\_Flow}_{ij} = G \times \frac{\left( \frac{1}{N_i} \sum_{k=1}^{N_i} \text{Raster}_i(k) \right) \times \left( \frac{1}{N_j} \sum_{k=1}^{N_j} \text{Raster}_j(k) \right)}{D_{ij}}
\]




