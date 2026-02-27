# ============================================================
# SAV Classification from PlanetScope (4-band)
# Author: Bikram Pandey
# Description:
# Rule-based classification of:
#   1 = Open Deep Water
#   2 = Shallow Water with Vegetation
#   3 = Submerged Aquatic Vegetation (SAV)
# ============================================================

library(terra)

# ------------------------------------------------------------
# 1. USER SETTINGS
# ------------------------------------------------------------

input_dir  <- "data/raw/"
output_dir <- "outputs/rasters/"
figure_dir <- "outputs/figures/"

blue_path  <- file.path(input_dir, "Baseline_dec_Blue.tif")
green_path <- file.path(input_dir, "Baseline_dec_Green.tif")
red_path   <- file.path(input_dir, "Baseline_dec_Red.tif")
nir_path   <- file.path(input_dir, "Baseline_dec_NIR.tif")

output_raster <- file.path(output_dir, "SAV_classification.tif")

# Create output folders if they don't exist
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(figure_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# 2. LOAD BANDS
# ------------------------------------------------------------

blue  <- rast(blue_path)
green <- rast(green_path)
red   <- rast(red_path)
nir   <- rast(nir_path)

# Reflectance scaling (PlanetScope often scaled by 10000)
if (global(red, "max", na.rm = TRUE)[1,1] > 1) {
  blue  <- blue  / 10000
  green <- green / 10000
  red   <- red   / 10000
  nir   <- nir   / 10000
}

# ------------------------------------------------------------
# 3. CALCULATE SPECTRAL INDICES
# ------------------------------------------------------------

ndvi  <- (nir - red) / (nir + red)
gndvi <- (nir - green) / (nir + green)
ndwi  <- (green - nir) / (green + nir)
ndavi <- (nir - blue) / (nir + blue)
ndti  <- (red - green) / (red + green)
wri   <- (green + red) / (nir + blue)
awei  <- (4 * (green - nir) - ((0.25 * nir) + (2.75 * red)))
savi  <- ((1 + 0.5) * ((nir - red) / (nir + red + 0.5)))
blue_ratio <- blue / green

# ------------------------------------------------------------
# 4. BASE WATER MASK
# ------------------------------------------------------------

all_water <- (ndwi > -0.2) &
  (wri  >  0.7) &
  (ndvi <  0.6)

# ------------------------------------------------------------
# 5. CLASS DEFINITIONS
# ------------------------------------------------------------

# ---- Open Deep Water ----
open_water <- all_water &
  (ndwi  >  0.2) &
  (awei  >  0.0) &
  (ndvi  < -0.1) &
  (ndavi <  0.05)

# ---- Shallow Zone ----
shallow_zone <- all_water &
  !open_water &
  (ndwi <  0.2) &
  (ndwi > -0.2) &
  (blue_ratio < 1.5)

# ---- SAV in Shallow Water (Dense SAV) ----
sav_shallow <- shallow_zone &
  (ndavi >  0.10) &
  (ndvi  >  0.08) &
  (ndvi  <  0.55) &
  (gndvi >  0.08) &
  (gndvi <  0.45) &
  (savi  >  0.05) &
  (ndti  <  0.12) &
  (blue_ratio < 1.3)

# ---- Shallow Water with Vegetation (Non-dense vegetation) ----
shallow_with_veg <- shallow_zone & !sav_shallow

# ---- SAV in Deeper Water ----
sav_deep <- all_water &
  !open_water &
  !shallow_zone &
  (ndwi  >  0.0) &
  (awei  >  0.0) &
  (ndavi >  0.05) &
  (ndvi  >  0.03) &
  (ndvi  <  0.30) &
  (gndvi >  0.03) &
  (ndti  <  0.08) &
  (blue_ratio < 1.2)

# ------------------------------------------------------------
# 6. RESOLVE CLASS PRIORITY
# ------------------------------------------------------------

open_water       <- open_water & !sav_deep & !sav_shallow
shallow_with_veg <- shallow_with_veg & !sav_deep

# ------------------------------------------------------------
# 7. BUILD CLASSIFIED RASTER
# ------------------------------------------------------------

# Class values:
# 1 = Open Deep Water
# 2 = Shallow Water with Vegetation
# 3 = SAV (Shallow + Deep)

classified <- (open_water       * 1) +
  (shallow_with_veg * 2) +
  (sav_shallow      * 3) +
  (sav_deep         * 3)

classified <- classify(classified, rbind(c(0, NA)))

# ------------------------------------------------------------
# 8. PLOT RESULT
# ------------------------------------------------------------

class_colors <- c("blue", "lightgreen", "red")

png(file.path(figure_dir, "SAV_classification_map.png"),
    width = 1000, height = 800)

plot(classified,
     col   = class_colors,
     main  = "SAV & Water Classification",
     legend = FALSE)

legend("bottomright",
       legend = c("Open Deep Water",
                  "Shallow Water with Vegetation",
                  "Submerged Aquatic Vegetation (SAV)"),
       fill   = class_colors,
       bty    = "n")

dev.off()

# ------------------------------------------------------------
# 9. AREA CALCULATION
# ------------------------------------------------------------

pixel_area <- prod(res(classified))

area_open        <- global(classified == 1, "sum", na.rm = TRUE)[1,1] * pixel_area
area_shallow_veg <- global(classified == 2, "sum", na.rm = TRUE)[1,1] * pixel_area
area_sav_total   <- global(classified == 3, "sum", na.rm = TRUE)[1,1] * pixel_area

cat("\n========================================\n")
cat("Open Deep Water (m²):              ", area_open, "\n")
cat("Shallow Water with Vegetation (m²):", area_shallow_veg, "\n")
cat("Total SAV Area (m²):               ", area_sav_total, "\n")
cat("Total SAV Area (ha):               ", area_sav_total / 10000, "\n")
cat("========================================\n")

# ------------------------------------------------------------
# 10. SAVE OUTPUT RASTER
# ------------------------------------------------------------

writeRaster(classified,
            output_raster,
            overwrite = TRUE)

# ------------------------------------------------------------
# END OF SCRIPT
# ------------------------------------------------------------