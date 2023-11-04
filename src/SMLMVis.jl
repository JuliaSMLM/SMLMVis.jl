module SMLMVis
 
# using GLMakie
using Images
using VideoIO

# include("visualization.jl")
include("video.jl")
include("mic/MIC.jl")
include("gauss_render/GaussRender.jl")


using SMLMVis.GaussRender
export render_blobs 


end
