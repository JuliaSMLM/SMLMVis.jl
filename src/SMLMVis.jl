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
