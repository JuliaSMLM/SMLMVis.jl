module GaussRender

using Images
using OffsetArrays
using ColorSchemes
using SMLMData

export render_blobs

include("blobrender.jl")
include("interface.jl")

end
