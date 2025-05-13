# Core types for the Render module

"""
Abstract type for different rendering strategies.
"""
abstract type RenderingStrategy end

"""
    GaussianBlobs <: RenderingStrategy

Strategy for rendering localizations as Gaussian blobs. Each localization is rendered
as a Gaussian intensity distribution with specified standard deviations.
"""
struct GaussianBlobs <: RenderingStrategy end

"""
    PointCloud <: RenderingStrategy

Strategy for rendering localizations as simple points. Each localization is rendered
as a single point, optionally with a size parameter.
"""
struct PointCloud <: RenderingStrategy end

"""
    ContrastMethod

Enumeration of contrast adjustment methods.
"""
@enum ContrastMethod begin
    Linear
    Logarithmic
    SquareRoot
    Equalize
end

"""
    ContrastOptions

Options for contrast adjustment in rendered images.
"""
struct ContrastOptions
    method::ContrastMethod
    clip::Float64  # Percentile for intensity clipping (0.0-1.0)
    
    # Constructor with validation
    function ContrastOptions(method::ContrastMethod, clip::Real)
        if !(0.0 <= clip <= 1.0)
            throw(ArgumentError("Clip value must be between 0.0 and 1.0"))
        end
        new(method, Float64(clip))
    end
end

# Convenience constructor from symbols
function ContrastOptions(; method::Symbol=:linear, clip::Real=0.995)
    method_enum = if method == :linear
        Linear
    elseif method == :log
        Logarithmic
    elseif method == :sqrt
        SquareRoot
    elseif method == :equalize
        Equalize
    else
        throw(ArgumentError("Unknown contrast method: $method"))
    end
    
    ContrastOptions(method_enum, clip)
end

"""
    RenderOptions

Configuration options for rendering SMLM data.
"""
struct RenderOptions
    strategy::RenderingStrategy
    color_by::Union{Symbol, Nothing}
    colormap::Symbol
    contrast::ContrastOptions
    n_sigmas::Float64  # Number of standard deviations to include for Gaussian blobs
    normalization::Symbol  # :integral or :maximum
    output_type::Symbol  # :array, :image
    
    # Constructor with validation
    function RenderOptions(
        strategy::RenderingStrategy,
        color_by::Union{Symbol, Nothing},
        colormap::Symbol,
        contrast::ContrastOptions,
        n_sigmas::Real,
        normalization::Symbol,
        output_type::Symbol
    )
        # Validate normalization
        if !(normalization in (:integral, :maximum))
            throw(ArgumentError("Normalization must be :integral or :maximum"))
        end
        
        # Validate output type
        if !(output_type in (:array, :image))
            throw(ArgumentError("Output type must be :array or :image"))
        end
        
        # Validate n_sigmas
        if n_sigmas <= 0
            throw(ArgumentError("n_sigmas must be positive"))
        end
        
        new(strategy, color_by, colormap, contrast, Float64(n_sigmas), normalization, output_type)
    end
end

# Convenience constructor with defaults
function RenderOptions(;
    strategy::RenderingStrategy = GaussianBlobs(),
    color_by::Union{Symbol, Nothing} = nothing,
    colormap::Symbol = :inferno,
    contrast::Union{ContrastOptions, NamedTuple} = ContrastOptions(),
    n_sigmas::Real = 3.0,
    normalization::Symbol = :integral,
    output_type::Symbol = :image  # Use :image for saving (ensures proper 8-bit format)
)
    # Convert NamedTuple to ContrastOptions if needed
    contrast_opts = if contrast isa NamedTuple
        ContrastOptions(; method=get(contrast, :method, :linear), clip=get(contrast, :clip, 0.995))
    else
        contrast
    end
    
    RenderOptions(
        strategy,
        color_by,
        colormap,
        contrast_opts,
        n_sigmas,
        normalization,
        output_type
    )
end

"""
    ImagePatch2D{T <: Real}

A 2D patch of an image with position offset information.
"""
struct ImagePatch2D{T <: Real}
    roi::Array{T, 2}  # Region of interest
    offset_x::Int     # X offset in global coordinates
    offset_y::Int     # Y offset in global coordinates
    value::T          # Associated value (e.g., z-coordinate)
end

"""
    ImagePatch3D{T <: Real}

A 3D patch of an image with position offset information.
"""
struct ImagePatch3D{T <: Real}
    roi::Array{T, 3}    # Region of interest
    offset_x::Int       # X offset in global coordinates
    offset_y::Int       # Y offset in global coordinates
    value::T            # Associated value (e.g., z-coordinate)
end

"""
    RGBArray{T <: Real}

A structure for storing RGB image data as separate channels.
"""
mutable struct RGBArray{T <: Real}
    r::Array{T, 2}
    g::Array{T, 2}
    b::Array{T, 2}
end

# Constructors for RGBArray
function RGBArray{T}(width::Integer, height::Integer) where T <: Real
    r = zeros(T, height, width)
    g = zeros(T, height, width)
    b = zeros(T, height, width)
    RGBArray{T}(r, g, b)
end

function RGBArray{T}(size::Tuple{Integer, Integer}) where T <: Real
    RGBArray{T}(size[1], size[2])
end

# Export rendering types
export RenderingStrategy, GaussianBlobs, PointCloud
export ContrastMethod, ContrastOptions, RenderOptions
export ImagePatch2D, ImagePatch3D, RGBArray