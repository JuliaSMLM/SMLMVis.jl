"""
    module SMLMVis

Julia package for visualization of Single Molecule Localization Microscopy (SMLM) data.

This package provides tools for:
1. Rendering localization data into images
2. Interactive visualization of SMLM data (planned)
3. Creating animations of SMLM data (planned)

The main functionality is provided by the Render module.
"""
module SMLMVis
 
# Include only the render module for now
include("render/Render.jl")

# Required packages
using Images

# Export from Render module
using SMLMVis.Render
export render, render_2d, render_3d

# Core functionality for SMLMVis module

"""
    api_overview()

Display an overview of the SMLMVis API.
"""
function api_overview()
    println("SMLMVis API Overview:")
    println("=====================")
    println("Main rendering functions:")
    println("  render(smld; zoom=20, color_by=nothing, colormap=:inferno, ...)")
    println("  render_2d(smld; ...)")
    println("  render_3d(smld; color_by=:z, ...)")
    println("\nFor more details, see the documentation.")
end

export api_overview

end