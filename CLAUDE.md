# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Package Overview

SMLMVis is a Julia package for visualization of Single Molecule Localization Microscopy (SMLM) data. It provides tools for rendering, visualization, animation, and file format conversion of SMLM data.

## Key Modules

1. **Render**: Generation of reconstructed super-resolution images from localization data
   - Core rendering functionality for 2D and 3D SMLM data
   - Supports coloring by various properties (intensity, z-position, frame, etc.)
   - Customizable rendering parameters (zoom, contrast, colormap)

2. **MIC**: Tools for MATLAB Instrument Control toolbox data conversion
   - Converts MIC data to MP4 format
   - Supports batch processing of files

3. **Interact**: Interactive visualization tools (in development)
   - Interactive visualization using GLMakie (conditional extension)

4. **Animate**: Time series and rotation animations (in development)
   - Animation functionality for time series and 3D rotations
   - Video export capabilities using FFmpeg (conditional extension)

## Development Commands

### Package Management

```julia
# Install dependencies in dev environment
cd(".julia/dev/SMLMVis")
using Pkg
Pkg.activate(".")
Pkg.instantiate()

# Install test-specific dependencies
Pkg.activate("test")
Pkg.instantiate()
Pkg.activate(".")
```

### Running Tests

```julia
# Run all tests
cd(".julia/dev/SMLMVis")
using Pkg
Pkg.test("SMLMVis")

# Run a specific test file
cd(".julia/dev/SMLMVis")
include("dev/test_basic.jl")
include("dev/test_render2d.jl")
include("dev/test_new_render.jl")
```

### Building Documentation

```julia
# Build documentation
cd(".julia/dev/SMLMVis")
include("docs/make.jl")
```

## Project Architecture

### Core Type System

- `RenderingStrategy`: Abstract type for different rendering approaches
- `GaussianBlobs`, `PointCloud`: Concrete strategy implementations
- `ContrastOptions`: Options for contrast adjustment
- `RenderOptions`: Complete rendering configuration
- `ImagePatch2D`, `ImagePatch3D`: For efficient rendering of localized regions
- `RGBArray`: Mutable structure for RGB image manipulation

### API Design Pattern

The rendering system follows a tiered API design:
1. High-level `render` function with sensible defaults
2. Mid-level function taking explicit pixel edges
3. Low-level implementation using blob rendering core

### Coordinate Handling

- SMLD data has coordinates in microns (μm)
- Camera pixel size typically 0.1 μm (100 nm)
- Rendered pixel size is camera_pixel_size/zoom (e.g., zoom=20 → 5nm pixels)
- PSF widths (σ values) are in microns and represent actual localization uncertainties
- When working with emitter coordinates:
  - (0,0) in physical space represents the top-left of the camera
  - Physical-to-pixel conversion: `SMLMData.physical_to_pixel(x, y, pixel_size)`
  - (1,1) in pixel coordinates represents the center of the top-left pixel

### Image Rendering

- `render` with default `output_type=:image` returns RGB{N0f8} images (8-bit RGB)
- For PNG files, images are automatically converted to 8-bit RGB format
- Set `output_type=:array` to get raw numerical values (not clamped to 0-1) for numerical processing
- Normalization options:
  - `:integral` - All blobs have the same integrated intensity (default)
  - `:maximum` - Higher precision (smaller σ) results in higher peak intensity

### Performance Considerations

- Multi-threaded rendering for performance
- Batch processing for memory efficiency with large datasets
- Proper memory management with mutable RGB arrays
- Optimized Gaussian blob generation

## Dependencies

- SMLMData v0.2.3 or higher: Core data structures for SMLM data
- Images: Image processing and manipulation
- ColorSchemes: Scientific colormaps
- HDF5: Reading MIC data
- VideoIO: Animation and video export capabilities (optional)
- GLMakie: Interactive visualization (optional)

## Exploring Related Package APIs

When working with SMLMVis, refer to the API overview documentation for related packages:

```julia
# Get API overview for SMLMData
using SMLMData
SMLMData.api_overview()

# Get SMLMSim API overview (note: might not print anything)
using SMLMSim
SMLMSim.api_overview()
```

### SMLMSim Integration

SMLMVis can render data from SMLMSim. We've created a test script `dev/test_smlmsim.jl` that demonstrates this integration:

```julia
# Run the test script
cd(".julia/dev/SMLMVis")
include("dev/test_smlmsim.jl")
```

The script:
1. Generates simulated SMLD data using SMLMSim
2. Renders the data with different zoom levels (1, 2, 5, 10)
3. Tests different normalization methods:
   - `:integral` - All blobs have the same integrated intensity
   - `:maximum` - Higher precision (smaller σ) results in higher peak intensity

All output images are saved to the `dev/output/` directory.

#### SMLMSim Usage Example

```julia
# Create a camera using SMLMData.IdealCamera
camera = SMLMData.IdealCamera(512, 512, 0.1)  # 512x512 pixels, 0.1 micron pixel size

# Create simulation parameters
params = SMLMSim.StaticSMLMParams(
    density=50.0,             # Density of molecules per μm²
    σ_psf=0.15,               # PSF width in μm (scalar for 2D)
    minphotons=100.0,         # Minimum photons for localization
    ndatasets=1,              # Number of datasets
    nframes=1000,             # Number of frames
    framerate=50.0,           # Frame rate in Hz
    ndims=2,                  # 2D simulation
    zrange=[-1.0, 1.0]        # Z range in microns (for 3D)
)

# Run simulation
smld_true, smld_model, smld_noisy = SMLMSim.simulate(params)

# Render the noisy data
img = render(smld_noisy;
    zoom = 5,
    color_by = :photons,
    colormap = :viridis,
    contrast = (method=:log, clip=0.99),
    normalization = :maximum  # Higher precision (smaller σ) results in higher peak intensity
)

# Save the rendered image
save("output.png", img)  # Automatically converts to 8-bit RGB for PNG format
```

Documentation for these packages is available in the API overview files located in the dev/api directory of the repository.