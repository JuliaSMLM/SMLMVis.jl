# SMLMVis

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaSMLM.github.io/SMLMVis.jl/stable/)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaSMLM.github.io/SMLMVis.jl/dev/)
[![Build Status](https://github.com/JuliaSMLM/SMLMVis.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/JuliaSMLM/SMLMVis.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Coverage](https://codecov.io/gh/JuliaSMLM/SMLMVis.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/JuliaSMLM/SMLMVis.jl)

## Overview

SMLMVis is a Julia package for visualization of Single Molecule Localization Microscopy (SMLM) data. It provides tools for rendering, visualization, animation, and file format conversion of SMLM data.

## Features

- **Flexible Rendering**: Create high-quality visualizations of SMLM data
- **2D and 3D Support**: Render both 2D and 3D localization data
- **Custom Coloring**: Color by any emitter property (intensity, z-position, frame, etc.)
- **Multiple Colormaps**: Support for various scientific colormaps
- **Contrast Adjustments**: Linear, logarithmic, square root, and equalization methods
- **MIC Conversion**: Convert MATLAB Instrument Control toolbox data to other formats

## Installation

```julia
using Pkg
Pkg.add("SMLMVis")
```

## Quick Start

### Basic Rendering

```julia
using SMLMVis
using SMLMData

# Create or load SMLD data
smld = ... # Your SMLD object

# Render with default settings
img = render(smld)

# Save the rendered image
using Images
save("my_image.png", img)
```

### Customized Rendering

```julia
# Render with custom settings
img = render(smld;
    zoom = 20,                     # Zoom factor
    color_by = :photons,           # Color by photon count
    colormap = :viridis,           # Use viridis colormap
    contrast = (method=:log, clip=0.99)  # Log contrast with 99% clip
)
```

### 3D Visualization

```julia
# Render 3D data with z-coloring
img_3d = render_3d(smld; 
    colormap = :turbo,             # Use turbo colormap for depth
    zoom = 15                      # Zoom factor
)
```

## Documentation

For more detailed information, see the [documentation](https://JuliaSMLM.github.io/SMLMVis.jl/dev/).

## Module Structure

SMLMVis is organized into three main modules:

1. **Render**: Generation of reconstructed super-resolution images from localization data
2. **Interact**: Interactive visualization tools (in development)
3. **Animate**: Time series and rotation animations (in development)

## Dependencies

- SMLMData v0.2.3 or higher
- Images
- ColorSchemes
- VideoIO (for animation)
- Optional: GLMakie (for interactive visualization)

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.