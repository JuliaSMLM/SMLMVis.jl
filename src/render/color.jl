# Color handling functions for rendering

using ColorSchemes
using Images
using Statistics
using SMLMData

"""
    get_colormap(name::Symbol)

Retrieve a colormap by name. Returns a ColorScheme object.
"""
function get_colormap(name::Symbol)
    try
        return colorschemes[name]
    catch e
        @warn "Colormap $name not found, using :inferno instead"
        return colorschemes[:inferno]
    end
end

"""
    get_color_values(smld::SMLMData.SMLD, color_by::Union{Symbol, Nothing})

Extract values from an SMLD object to use for coloring the rendered image.
When color_by is nothing, returns a vector of ones for uniform coloring.
"""
function get_color_values(smld::SMLMData.SMLD, color_by::Union{Symbol, Nothing})
    n_emitters = length(smld.emitters)
    
    if isnothing(color_by)
        # Return uniform values for single-color rendering
        return ones(n_emitters)
    end
    
    # Handle special cases first
    if color_by == :intensity || color_by == :photons
        # Get photon values directly from emitters
        return [e.photons for e in smld.emitters]
    elseif color_by == :z && hasfield(typeof(first(smld.emitters)), :z)
        # Get z values for 3D emitters
        return [e.z for e in smld.emitters]
    elseif color_by == :x 
        # Get x values directly from emitters
        return [e.x for e in smld.emitters]
    elseif color_by == :y
        # Get y values directly from emitters
        return [e.y for e in smld.emitters]
    elseif color_by == :frame
        # Use frame information if available
        if hasfield(typeof(first(smld.emitters)), :frame)
            return [e.frame for e in smld.emitters]
        else
            @warn "No frame information found, using uniform coloring"
            return ones(n_emitters)
        end
    elseif color_by == :uncertainty
        # Calculate localization uncertainty if σ values are available
        if hasfield(typeof(first(smld.emitters)), :σ_x) && 
           hasfield(typeof(first(smld.emitters)), :σ_y)
            return [sqrt(e.σ_x^2 + e.σ_y^2) for e in smld.emitters]
        else
            @warn "No uncertainty (σ) values found, using uniform coloring"
            return ones(n_emitters)
        end
    elseif color_by == :bg && hasfield(typeof(first(smld.emitters)), :bg)
        # Get background values
        return [e.bg for e in smld.emitters]
    elseif color_by == :dataset && hasfield(typeof(first(smld.emitters)), :dataset)
        # Get dataset identifier values
        return [e.dataset for e in smld.emitters]
    elseif color_by == :track_id && hasfield(typeof(first(smld.emitters)), :track_id)
        # Get track identifiers
        return [e.track_id for e in smld.emitters]
    end
    
    # Try to access field directly from emitter
    if n_emitters > 0 && hasfield(typeof(first(smld.emitters)), color_by)
        return [getfield(e, color_by) for e in smld.emitters]
    end
    
    # If we can't find the field, throw an error
    error("Cannot find field '$color_by' in emitters")
end

"""
    apply_colormap(gray_image::AbstractArray{T,2}, 
                  colormap::ColorScheme, 
                  contrast::ContrastOptions) where T <: Real

Apply a colormap to a grayscale image with contrast adjustment.
"""
function apply_colormap(gray_image::AbstractArray{T,2}, 
                       colormap::ColorScheme, 
                       contrast::ContrastOptions) where T <: Real
    
    # Create a copy of the image for processing
    img = copy(gray_image)
    
    # Apply contrast adjustment
    apply_contrast!(img, contrast)
    
    # Map values to colors
    height, width = size(img)
    rgb_image = Array{RGB{Float32}}(undef, height, width)
    
    for i in 1:height, j in 1:width
        # Get color from colormap (clamp to ensure within 0-1 range)
        val = clamp(img[i, j], 0, 1)
        rgb_image[i, j] = get(colormap, val)
    end
    
    return rgb_image
end

"""
    apply_colormap(rgb_array::RGBArray{T}, 
                  contrast::ContrastOptions) where T <: Real

Apply contrast adjustment to an RGBArray and convert to an RGB image.
"""
function apply_colormap(rgb_array::RGBArray{T}, 
                       contrast::ContrastOptions) where T <: Real
    
    # Create a copy of each channel
    r_channel = copy(rgb_array.r)
    g_channel = copy(rgb_array.g)
    b_channel = copy(rgb_array.b)
    
    # Apply contrast to each channel
    apply_contrast!(r_channel, contrast)
    apply_contrast!(g_channel, contrast)
    apply_contrast!(b_channel, contrast)
    
    # Convert to RGB image
    height, width = size(r_channel)
    rgb_image = Array{RGB{Float32}}(undef, height, width)
    
    for i in 1:height, j in 1:width
        rgb_image[i, j] = RGB{Float32}(
            r_channel[i, j],
            g_channel[i, j],
            b_channel[i, j]
        )
    end
    
    return rgb_image
end

"""
    apply_contrast!(img::AbstractArray{T,N}, 
                   contrast::ContrastOptions) where {T <: Real, N}

Apply contrast adjustment to an image in-place.
"""
function apply_contrast!(img::AbstractArray{T,N}, 
                        contrast::ContrastOptions) where {T <: Real, N}
    
    # Skip processing if image is empty or all zeros
    all(v -> v == zero(T), img) && return img
    
    # Apply method-specific transformations
    if contrast.method == Linear
        # Linear contrast stretch is performed at the end
    elseif contrast.method == Logarithmic
        # Avoid log(0)
        eps_val = eps(T)
        img .= log.(max.(img, eps_val))
    elseif contrast.method == SquareRoot
        img .= sqrt.(max.(img, zero(T)))
    elseif contrast.method == Equalize
        # Histogram equalization
        # This is a simplified version, full equalization would require binning
        sorted_vals = sort(filter(x -> x > zero(T), vec(img)))
        if !isempty(sorted_vals)
            n = length(sorted_vals)
            for i in eachindex(img)
                if img[i] > zero(T)
                    # Find approximate rank in sorted array (this could be optimized)
                    rank = searchsortedfirst(sorted_vals, img[i])
                    img[i] = (rank - 1) / (n - 1)
                end
            end
        end
        return img  # Early return as no further normalization needed
    end
    
    # Identify non-zero values for percentile calculation
    nonzero_values = filter(x -> x > zero(T), vec(img))
    
    if !isempty(nonzero_values)
        # Find the upper percentile value for clipping
        max_val = quantile(nonzero_values, contrast.clip)
        
        # Normalize the image to 0-1 range
        min_val = minimum(nonzero_values)
        
        # Apply normalization, clipping values above max_val
        for i in eachindex(img)
            if img[i] > zero(T)
                img[i] = min(img[i], max_val)
                img[i] = (img[i] - min_val) / (max_val - min_val)
            end
        end
    end
    
    return img
end

"""
    map_values_to_colormap(values::AbstractVector{T}, 
                          colormap::ColorScheme, 
                          value_range::Union{Tuple{Real,Real}, Nothing}=nothing) where T <: Real

Map a vector of values to colors using a colormap.
"""
function map_values_to_colormap(values::AbstractVector{T}, 
                               colormap::ColorScheme, 
                               value_range::Union{Tuple{Real,Real}, Nothing}=nothing) where T <: Real
    
    if isempty(values)
        return RGB{Float32}[]
    end
    
    # Determine the value range if not provided
    if isnothing(value_range)
        min_val = minimum(values)
        max_val = maximum(values)
        
        # Handle case where all values are the same
        if min_val == max_val
            min_val = min_val - 0.5
            max_val = max_val + 0.5
        end
    else
        min_val, max_val = value_range
    end
    
    range_size = max_val - min_val
    
    # Map each value to a color
    colors = Vector{RGB{Float32}}(undef, length(values))
    for i in eachindex(values)
        # Normalize to 0-1 range
        normalized = (values[i] - min_val) / range_size
        # Clamp to ensure within valid range
        normalized = clamp(normalized, 0.0, 1.0)
        # Get color from colormap
        colors[i] = get(colormap, normalized)
    end
    
    return colors
end

# Export color-related functions
export get_colormap, get_color_values, apply_colormap
export apply_contrast!, map_values_to_colormap