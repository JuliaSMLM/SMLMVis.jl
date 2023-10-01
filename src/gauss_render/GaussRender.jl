module GaussRender

using Images
using OffsetArrays
using ColorSchemes
using SMLMData
using Statistics 

export render_blobs

include("blobrender.jl")
include("interface.jl")

end
