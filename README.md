# SAV_classification-using-PlanetScope
Description: A threshold-based multispectral classification workflow for submerged aquatic vegetation (SAV) detection using 4-band imagery. The method computes spectral indices (NDVI, NDWI, NDAVI, AWEI, and others), applies hierarchical class rules, and outputs classified rasters and area statistics. Suitable for aquatic ecosystem analysis.

# Submerged Aquatic Vegetation (SAV) Classification from PlanetScope

## Overview

This repository provides a rule-based workflow for detecting and mapping **Submerged Aquatic Vegetation (SAV)** using 4-band PlanetScope multispectral imagery.

The script performs:

- Spectral index calculation
- Water masking
- SAV classification
- Area estimation (m² and hectares)
- GeoTIFF export
- Map visualization export

This workflow is designed for ecological monitoring, blue carbon assessment, and coastal habitat mapping.

---

## Classification Scheme

The output raster contains three classes:

| Class Value | Description                              |
|------------|------------------------------------------|
| 1          | Open Deep Water                          |
| 2          | Shallow Water with Vegetation            |
| 3          | Submerged Aquatic Vegetation (SAV)       |

---

## Spectral Indices Used

The classification uses multiple spectral indices:

- NDVI
- GNDVI
- NDWI
- NDAVI
- NDTI
- WRI
- AWEI
- SAVI
- Blue/Green Ratio

These indices help separate:

- Open water
- Shallow water zones
- Dense submerged vegetation
- Turbid water
- Non-aquatic vegetation

---
