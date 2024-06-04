# Struct definition
struct RGBArray{T<:Real}
    r::AbstractArray{T}
    g::AbstractArray{T}
    b::AbstractArray{T}
end

# Constructors
function RGBArray{T}(sz::Tuple) where T<:Real
    r = OffsetArray(zeros(T, sz...))
    g = OffsetArray(zeros(T, sz...))
    b = OffsetArray(zeros(T, sz...))
    return RGBArray{T}(r, g, b)
end

function RGBArray{T}(dims...) where T<:Real
    return RGBArray{T}(Tuple(dims))
end

function RGBArray{T}(sz::Tuple, ranges::Tuple) where T<:Real
    return RGBArray(
        OffsetArray(zeros(T, sz...), ranges...),
        OffsetArray(zeros(T, sz...), ranges...),
        OffsetArray(zeros(T, sz...), ranges...)
    )
end

# Modified Blob struct with manual offset fields
abstract type ImagePatch end 

struct ImagePatch2D{T<:Real} <: ImagePatch
    roi :: Array{T, 2}
    offset_x :: Int
    offset_y :: Int
    z :: T
end

struct ImagePatch3D{T<:Real} <: ImagePatch
    roi :: Array{T, 3}
    offset_x :: Int
    offset_y :: Int
    z :: T
end


