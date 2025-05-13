# SMLMData.jl API Overview

This guide provides a structured overview of the SMLMData.jl package designed for Single Molecule Localization Microscopy (SMLM) data handling in Julia.

## Key Concepts

- **Emitters**: Individual fluorophore localizations (2D or 3D)
- **Camera**: Defines pixel geometry and coordinate system
- **SMLD**: Container holding emitters and camera information
- **Coordinates**: All spatial coordinates are in **microns**
- **Coordinate System**: 
  - Physical space: (0,0) at top-left corner of camera
  - Pixel space: (1,1) at center of top-left pixel

## Type Hierarchy

```
AbstractEmitter                   # Base for all emitter types
├── Emitter2D{T}                  # Basic 2D emitters
├── Emitter3D{T}                  # Basic 3D emitters  
├── Emitter2DFit{T}               # 2D emitters with fit results
└── Emitter3DFit{T}               # 3D emitters with fit results

AbstractCamera                    # Base for all camera types
└── IdealCamera{T}                # Camera with regular pixel grid

SMLD                              # Base for data containers
├── BasicSMLD{T,E}                # General-purpose container
└── SmiteSMLD{T,E}                # SMITE-compatible container
```

## Essential Types

### Emitter Types

```julia
# Basic 2D emitter
struct Emitter2D{T} <: AbstractEmitter
    x::T           # x-coordinate in microns
    y::T           # y-coordinate in microns
    photons::T     # number of photons emitted
end

# Basic 3D emitter
struct Emitter3D{T} <: AbstractEmitter
    x::T           # x-coordinate in microns
    y::T           # y-coordinate in microns
    z::T           # z-coordinate in microns
    photons::T     # number of photons emitted
end

# 2D emitter with fit results
mutable struct Emitter2DFit{T} <: AbstractEmitter
    x::T           # fitted x-coordinate in microns
    y::T           # fitted y-coordinate in microns
    photons::T     # fitted number of photons
    bg::T          # fitted background in photons/pixel
    σ_x::T         # uncertainty in x position in microns
    σ_y::T         # uncertainty in y position in microns
    σ_photons::T   # uncertainty in photon count
    σ_bg::T        # uncertainty in background level
    frame::Int     # frame number in acquisition sequence
    dataset::Int   # identifier for specific acquisition/dataset
    track_id::Int  # identifier for linking localizations across frames
    id::Int        # unique identifier within dataset
end

# 3D emitter with fit results
mutable struct Emitter3DFit{T} <: AbstractEmitter
    x::T           # fitted x-coordinate in microns
    y::T           # fitted y-coordinate in microns
    z::T           # fitted z-coordinate in microns
    photons::T     # fitted number of photons
    bg::T          # fitted background in photons/pixel
    σ_x::T         # uncertainty in x position in microns
    σ_y::T         # uncertainty in y position in microns
    σ_z::T         # uncertainty in z position in microns
    σ_photons::T   # uncertainty in photon count
    σ_bg::T        # uncertainty in background level
    frame::Int     # frame number in acquisition sequence
    dataset::Int   # identifier for specific acquisition/dataset
    track_id::Int  # identifier for linking localizations across frames
    id::Int        # unique identifier within dataset
end
```

#### Emitter Constructor Examples

```julia
# Basic 2D emitter
emitter_2d = Emitter2D{Float64}(1.5, 2.3, 1000.0)  # x, y, photons

# Basic 3D emitter
emitter_3d = Emitter3D{Float64}(1.5, 2.3, -0.5, 1000.0)  # x, y, z, photons

# 2D emitter with fit results using convenience constructor
emitter_2d_fit = Emitter2DFit{Float64}(
    1.5, 2.3,        # x, y coordinates (μm)
    1000.0, 10.0,    # photons, background
    0.01, 0.01,      # σ_x, σ_y (uncertainties in μm)
    50.0, 2.0;       # σ_photons, σ_bg (uncertainties)
    frame=5,         # frame number
    dataset=1,       # dataset identifier
    track_id=2,      # tracking identifier (0 = unlinked)
    id=42            # unique identifier
)
```

### Camera Types

```julia
# Camera with uniform pixel grid
struct IdealCamera{T} <: AbstractCamera
    pixel_edges_x::Vector{T}  # pixel edges in x
    pixel_edges_y::Vector{T}  # pixel edges in y
end
```

#### Camera Constructor Examples

```julia
# Create a camera with 512x512 pixels, each 100nm (0.1μm) in size
cam = IdealCamera(512, 512, 0.1)

# For non-square pixels, specify different x and y sizes
cam_rect = IdealCamera(512, 512, (0.1, 0.12))
```

### SMLD Container Types

```julia
# Basic SMLD container
struct BasicSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}        # Vector of emitters
    camera::AbstractCamera     # Camera information
    n_frames::Int              # Total number of frames
    n_datasets::Int            # Number of datasets
    metadata::Dict{String,Any} # Additional information
end

# SMITE format compatible container
struct SmiteSMLD{T,E<:AbstractEmitter} <: SMLD
    emitters::Vector{E}        # Vector of emitters
    camera::AbstractCamera     # Camera information
    n_frames::Int              # Total number of frames
    n_datasets::Int            # Number of datasets
    metadata::Dict{String,Any} # Additional information
end
```

#### SMLD Constructor Examples

```julia
# Create a vector of emitters
emitters = [
    Emitter2DFit{Float64}(1.0, 2.0, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0),
    Emitter2DFit{Float64}(3.0, 4.0, 1200.0, 12.0, 0.01, 0.01, 60.0, 2.0)
]

# Create a BasicSMLD
smld = BasicSMLD(emitters, camera, 1, 1, Dict{String,Any}())

# Add metadata
smld_with_metadata = BasicSMLD(
    emitters, 
    camera, 
    10,  # number of frames
    1,   # number of datasets
    Dict{String,Any}(
        "exposure_time" => 0.1,
        "sample" => "Test Sample"
    )
)
```

## Core Functions

### Coordinate Conversions

```julia
# Convert from pixel to physical coordinates (microns)
x_physical, y_physical = pixel_to_physical(px, py, pixel_size)

# Convert from physical to pixel coordinates
px, py = physical_to_pixel(x, y, pixel_size)

# Convert from physical to pixel indices (integers)
px_idx, py_idx = physical_to_pixel_index(x, y, pixel_size)

# Get physical coordinates of all pixel centers
centers_x, centers_y = get_pixel_centers(camera)
```

### Filtering Operations

```julia
# Filter by emitter properties using @filter macro
bright = @filter(smld, photons > 1000)
precise = @filter(smld, σ_x < 0.02 && σ_y < 0.02)
combined = @filter(smld, photons > 1000 && σ_x < 0.02 && σ_y < 0.02)

# Select frames
frame_5 = filter_frames(smld, 5)
early_frames = filter_frames(smld, 1:10)
specific_frames = filter_frames(smld, [1,3,5,7])

# Select region of interest (ROI)
# 2D ROI
roi_2d = filter_roi(smld, 1.0:5.0, 2.0:6.0)  # x_range, y_range

# 3D ROI (for 3D emitters only)
roi_3d = filter_roi(smld, 1.0:5.0, 2.0:6.0, -1.0:1.0)  # x_range, y_range, z_range
```

### SMLD Operations

```julia
# Concatenate multiple SMLDs
combined = cat_smld(smld1, smld2)
combined = cat_smld([smld1, smld2, smld3])

# Merge with options to adjust frame and dataset numbering
merged = merge_smld(smld1, smld2)
merged = merge_smld([smld1, smld2, smld3])

# Merge with sequential frame numbers
sequential = merge_smld([smld1, smld2, smld3], adjust_frames=true)

# Merge with sequential dataset numbers
sequential_ds = merge_smld([smld1, smld2, smld3], adjust_datasets=true)
```

### I/O Operations

```julia
# Import from SMITE format (MATLAB)
smd = SmiteSMD("path/to/data", "localizations.mat")  # Default variable name "SMD"
smd = SmiteSMD("path/to/data", "localizations.mat", "CustomSMD")  # Custom variable name

# Load as 2D or 3D data
smld_2d = load_smite_2d(smd)
smld_3d = load_smite_3d(smd)

# Export to SMITE format
save_smite(smld, "output/directory", "results.mat")
```

## Common Workflows

### Creating and Working with Emitters

```julia
# Create emitters
emitter1 = Emitter2DFit{Float64}(1.0, 2.0, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0)
emitter2 = Emitter2DFit{Float64}(3.0, 4.0, 1200.0, 12.0, 0.01, 0.01, 60.0, 2.0)

# Create camera
cam = IdealCamera(512, 512, 0.1)  # 512x512 camera with 0.1 micron pixels

# Create SMLD container
emitters = [emitter1, emitter2]
smld = BasicSMLD(emitters, cam, 1, 1, Dict{String,Any}())
```

### Loading and Filtering Data

```julia
# Load from SMITE format
smd = SmiteSMD("data_directory", "localizations.mat")
smld = load_smite_2d(smd)

# Filter by quality
good_fits = @filter(smld, σ_x < 0.02 && σ_y < 0.02 && photons > 500)

# Filter by ROI
roi = filter_roi(good_fits, 10.0:20.0, 10.0:20.0)

# Filter by frames
frames_1_10 = filter_frames(roi, 1:10)
```

### Multi-Dataset Analysis

```julia
# Load multiple datasets
smd1 = SmiteSMD("experiment1", "data.mat")
smd2 = SmiteSMD("experiment2", "data.mat")
smld1 = load_smite_2d(smd1)
smld2 = load_smite_2d(smd2)

# Filter each dataset
bright1 = @filter(smld1, photons > 1000)
bright2 = @filter(smld2, photons > 1000)

# Merge datasets with sequential frame numbering
merged = merge_smld([bright1, bright2], adjust_frames=true)

# Process the merged dataset
result = @filter(merged, σ_x < 0.02 && σ_y < 0.02)

# Save the results
save_smite(result, "analysis_results", "merged_filtered.mat")
```

## Complete Example

```julia
using SMLMData

# 1. Create a camera with 100nm pixels
cam = IdealCamera(512, 512, 0.1)  

# 2. Create emitters
emitters = [
    Emitter2DFit{Float64}(1.0, 2.0, 1000.0, 10.0, 0.01, 0.01, 50.0, 2.0),
    Emitter2DFit{Float64}(3.0, 4.0, 1200.0, 12.0, 0.01, 0.01, 60.0, 2.0),
    Emitter2DFit{Float64}(5.0, 6.0, 800.0, 9.0, 0.03, 0.03, 40.0, 1.5)
]

# 3. Create SMLD container
smld = BasicSMLD(emitters, cam, 1, 1, Dict{String,Any}("sample" => "Test"))

# 4. Filter by photons
bright = @filter(smld, photons > 900)

# 5. Select region of interest
roi = filter_roi(bright, 0.0:4.0, 1.0:5.0)

# 6. Examine the results
println("Original dataset: $(length(smld)) emitters")
println("After filtering by brightness: $(length(bright)) emitters")
println("After ROI selection: $(length(roi)) emitters")

# Output:
# Original dataset: 3 emitters
# After filtering by brightness: 2 emitters
# After ROI selection: 2 emitters
```