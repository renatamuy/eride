# Mathematical Representation of the Gravity Model

## Table of Contents

1. [Provinces to Keep](#1-provinces-to-keep)
2. [Reading Spatial Data and Calculating Centroids](#2-reading-spatial-data-and-calculating-centroids)
3. [Extracting Mean Raster Values (PAR)](#3-extracting-mean-raster-values-par)
4. [Calculating Pairwise Distances Between Centroids](#4-calculating-pairwise-distances-between-centroids)
5. [Creating Pairwise Region Interactions Data Frame](#5-creating-pairwise-region-interactions-data-frame)
6. [Applying the Gravity Model Formula](#6-applying-the-gravity-model-formula)
7. [Summary of the Gravity Model](#7-summary-of-the-gravity-model)

---

## 1. Provinces to Keep

Let \( K \) be the set of provinces to retain:

\[
K = \{\text{Banten},\ \text{West Java},\ \text{Central Java},\ \text{Yogyakarta},\ \text{East Java},\ \text{Bali}\}
\]

## 2. Reading Spatial Data and Calculating Centroids

For each region \( i \) in \( K \), determine its centroid \( C_i \):

\[
C_i = \text{Centroid of region } i
\]

## 3. Extracting Mean Raster Values (PAR)

Calculate the mean population at risk value for each region \( i \):

\[
\text{PAR}_i = \frac{1}{N_i} \sum_{k=1}^{N_i} \text{Raster}(k)
\]

**Where:**
- \( N_i \) is the number of raster cells in region \( i \).
- \( \text{Raster}(k) \) represents the raster value of the \( k \)-th cell in region \( i \).

## 4. Calculating Pairwise Distances Between Centroids

Compute the geographic distance \( D_{ij} \) between the centroids of regions \( i \) and \( j \):

\[
D_{ij} =
\begin{cases}
0 & \text{if } i = j \\
\frac{\text{distGeo}(C_i, C_j)}{1000} & \text{if } i \neq j
\end{cases}
\]

**Where:**
- \( \text{distGeo}(C_i, C_j) \) calculates the geographic distance in meters between centroids \( C_i \) and \( C_j \).
- Dividing by 1000 converts the distance to kilometers.

## 5. Creating Pairwise Region Interactions Data Frame

Construct a data frame \( \text{Gravity\_Data} \) containing all unique pairs of regions with their corresponding PAR values and distances:

\[
\text{Gravity\_Data} = \left\{ 
\left( 
\text{Region}_A, \text{Region}_B, \text{PAR}_A, \text{PAR}_B, D_{AB} 
\right) \ \bigg| \ \text{Region}_A, \text{Region}_B \in K,\ \text{Region}_A \neq \text{Region}_B 
\right\}
\]

## 6. Applying the Gravity Model Formula

The gravity model estimates the risk flow \( \text{Risk\_Flow}_{ij} \) between regions \( i \) and \( j \) as:

\[
\text{Risk\_Flow}_{ij} = G \times \frac{\text{PAR}_i \times \text{PAR}_j}{D_{ij}}
\]

**Where:**
- \( G \) is a constant (e.g., \( G = 1 \)).
- \( \text{PAR}_i \) and \( \text{PAR}_j \) are the mean raster values for regions \( i \) and \( j \), respectively.
- \( D_{ij} \) is the distance between the centroids of regions \( i \) and \( j \).

## 7. Summary of the Gravity Model

Combining the above steps, the gravity model can be summarized as:

\[
\text{Risk\_Flow}_{ij} = G \times \frac{\left( \frac{1}{N_i} \sum_{k=1}^{N_i} \text{Raster}_i(k) \right) \times \left( \frac{1}{N_j} \sum_{k=1}^{N_j} \text{Raster}_j(k) \right)}{D_{ij}}
\]

**Where:**
- The main outcome is the PAR risk flow given between two regions.
