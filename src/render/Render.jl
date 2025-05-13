"""
    module Render

Module for rendering Single Molecule Localization Microscopy (SMLM) data.

This module provides functions for converting SMLM localization data into
rendered images, with support for both 2D and 3D data, various coloring
options, and different rendering strategies.

The main entry point is the `render` function, which takes an SMLD
(SMLM data) object and various optional parameters to control the
rendering process.

# Examples
```julia
using SMLMVis
using SMLMData

# Load or create SMLD data
smld = SMLD2D(...)

# Render with default parameters
image = render(smld)

# Render with custom parameters
image = render(smld;
    zoom = 20,              # Zoom factor
    color_by = :z,          # Color by z-coordinate
    colormap = :viridis,    # Use viridis colormap
    contrast = (method=:log, clip=0.99)  # Logarithmic contrast with 99% clip
)

# Render with explicit pixel edges
x_edges = 1:1000
y_edges = 1:800
image = render(smld, x_edges, y_edges)

# Export to file
using Images
save("rendered_image.png", image)
```
"""
module Render

using SMLMData
using Images
using ColorSchemes
using Statistics

# Export main functions
export render, render_2d, render_3d

# Include type definitions
include("types.jl")

# Include utility functions
include("utils.jl")

# Include color handling functions
include("color.jl")

# Include core rendering functions
include("core.jl")

# Include high-level interface
include("interface.jl")

end # module Render