"""
    module SMLMVis

Julia package for visualization of Single Molecule Localization Microscopy (SMLM) data.

This package provides tools for:
1. Rendering localization data into images
2. Interactive visualization of SMLM data (planned)
3. Creating animations of SMLM data (planned)
4. Converting between different file formats

The main functionality is divided into several submodules:
- `Render`: For rendering localization data into images
- `MIC`: For handling MATLAB Instrument Control toolbox data
"""
module SMLMVis
 
# Include core modules
include("video.jl")
include("mic/MIC.jl")
include("render/Render.jl")

# Required packages
using Images
using VideoIO

# Export from Render module
using SMLMVis.Render
export render, render_2d, render_3d

# Export from MIC module
using SMLMVis.MIC
export mic2mp4

# Conditionally load extension modules if dependencies are available
# This will be handled by Julia's extension mechanism

end