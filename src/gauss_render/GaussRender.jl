"""
    module GaussRender

Methods for rendering Gaussian blobs into images.

The primary exported function is the `render_blobs` function, which takes a
`SMLMData.SMLD` structure and renders it into an image. The image is returned
as a `ColorTypes.RGB{Float32}` array.

This can be saved as a PNG file using the `save` function from the `Images` package.
"""
module GaussRender

using Images
using OffsetArrays
using ColorSchemes
using SMLMData
using Statistics 
using ImageView
export render_blobs

include("types.jl")
include("blobrender.jl")
include("color.jl") 
include("helpers.jl")
include("interface.jl")

end
