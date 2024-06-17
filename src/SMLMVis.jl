"""
The `SMLMVis` module is designed for visualization tasks specifically tailored for Single Molecule Localization Microscopy (SMLM). This module includes functionalities for video processing and Gaussian rendering of microscopy data.

    ## Dependencies
    To use the `SMLMVis` module, ensure that the following packages are installed and included:
    
    - `GLMakie`: For high-performance visualizations.
    - `Images`: For handling image data.
    - `VideoIO`: For video processing capabilities.
    
""" 
module SMLMVis
 
# include("visualization.jl")
include("video.jl")
include("mic/MIC.jl")
include("gauss_render/GaussRender.jl")

# using GLMakie
using Images
using VideoIO

using SMLMVis.GaussRender
export render_blobs 

using SMLMVis.MIC
export mic2mp4

end
