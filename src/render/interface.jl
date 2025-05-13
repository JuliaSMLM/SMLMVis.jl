# High-level rendering interface

using SMLMData
using Images

"""
    render(smld::SMLMData.SMLD; 
          zoom::Integer=20,
          color_by::Union{Symbol, Nothing}=nothing,
          colormap::Symbol=:inferno,
          contrast::Union{ContrastOptions, NamedTuple}=ContrastOptions(),
          n_sigmas::Real=3.0,
          normalization::Symbol=:integral,
          output_type::Symbol=:array)

Render SMLM data using the specified parameters.

# Arguments
- `smld::SMLMData.SMLD`: The SMLM data to render
- `zoom::Integer=20`: The zoom factor to apply to the pixel size
- `color_by::Union{Symbol, Nothing}=nothing`: The field to use for coloring, or nothing for uniform coloring
- `colormap::Symbol=:inferno`: The colormap to use
- `contrast::Union{ContrastOptions, NamedTuple}=ContrastOptions()`: The contrast adjustment options
- `n_sigmas::Real=3.0`: The number of standard deviations to include for each blob
- `normalization::Symbol=:integral`: The normalization method, either `:integral` or `:maximum`
- `output_type::Symbol=:array`: The type of output, either `:array` or `:image`

# Returns
- The rendered image as either an RGB array or an RGB image, depending on output_type
"""
function render(smld::SMLMData.SMLD; 
               zoom::Integer=20,
               color_by::Union{Symbol, Nothing}=nothing,
               colormap::Symbol=:inferno,
               contrast::Union{ContrastOptions, NamedTuple}=ContrastOptions(),
               n_sigmas::Real=3.0,
               normalization::Symbol=:integral,
               output_type::Symbol=:array)
    
    # Create render options
    options = RenderOptions(
        GaussianBlobs(),
        color_by,
        colormap,
        contrast isa NamedTuple ? ContrastOptions(; contrast...) : contrast,
        n_sigmas,
        normalization,
        output_type
    )
    
    # Calculate pixel edges based on zoom factor
    x_edges, y_edges = calculate_pixel_edges(smld, zoom)
    
    # Call the pixel-edge based render function
    return render(smld, x_edges, y_edges; options=options)
end

"""
    render(smld::SMLMData.SMLD, 
          x_edges::AbstractVector{<:Integer}, 
          y_edges::AbstractVector{<:Integer}; 
          options::RenderOptions=RenderOptions())

Render SMLM data using explicit pixel edges.

# Arguments
- `smld::SMLMData.SMLD`: The SMLM data to render
- `x_edges::AbstractVector{<:Integer}`: The x-coordinates of the pixel edges
- `y_edges::AbstractVector{<:Integer}`: The y-coordinates of the pixel edges
- `options::RenderOptions=RenderOptions()`: The rendering options

# Returns
- The rendered image as either an RGB array or an RGB image, depending on options.output_type
"""
function render(smld::SMLMData.SMLD, 
               x_edges::AbstractVector{<:Integer}, 
               y_edges::AbstractVector{<:Integer}; 
               options::RenderOptions=RenderOptions())
    
    # Check if SMLD is empty
    if isempty(smld.emitters)
        @warn "SMLD contains no emitters, returning blank image"
        width = length(x_edges)
        height = length(y_edges)
        return options.output_type == :image ? 
            RGB{N0f8}.(zeros(Float64, height, width, 3)) :
            zeros(RGB{Float32}, height, width)
    end
    
    # Calculate coordinate ranges
    x_range = (minimum(x_edges), maximum(x_edges))
    y_range = (minimum(y_edges), maximum(y_edges))
    
    # Get the rendering strategy
    if options.strategy isa GaussianBlobs
        # Use Gaussian blob rendering
        return render_gaussian(smld, x_range, y_range, options)
    elseif options.strategy isa PointCloud
        # Use point cloud rendering (future implementation)
        @warn "Point cloud rendering not yet implemented, falling back to Gaussian blobs"
        return render_gaussian(smld, x_range, y_range, options)
    else
        error("Unknown rendering strategy: $(typeof(options.strategy))")
    end
end

"""
    render_gaussian(smld::SMLMData.SMLD, 
                   x_range::Tuple{<:Real, <:Real}, 
                   y_range::Tuple{<:Real, <:Real}, 
                   options::RenderOptions)

Render SMLM data using Gaussian blobs.

# Arguments
- `smld::SMLMData.SMLD`: The SMLM data to render
- `x_range::Tuple{<:Real, <:Real}`: The range of valid x-coordinates
- `y_range::Tuple{<:Real, <:Real}`: The range of valid y-coordinates
- `options::RenderOptions`: The rendering options

# Returns
- The rendered image as either an RGB array or an RGB image, depending on options.output_type
"""
function render_gaussian(smld::SMLMData.SMLD, 
                        x_range::Tuple{<:Real, <:Real}, 
                        y_range::Tuple{<:Real, <:Real}, 
                        options::RenderOptions)
    
    # Check if SMLD emitters is empty
    if isempty(smld.emitters)
        @warn "SMLD contains no emitters, returning blank image"
        width = round(Int, x_range[2] - x_range[1] + 1)
        height = round(Int, y_range[2] - y_range[1] + 1)
        rgb_image = options.output_type == :image ? 
            RGB{N0f8}.(zeros(Float64, height, width, 3)) :
            zeros(RGB{Float32}, height, width)
        return rgb_image
    end
    
    # Extract coordinates from emitters
    x = [e.x for e in smld.emitters]
    y = [e.y for e in smld.emitters]
    
    # Debug coordinate information
    @info "Render input:" length(smld.emitters) x_range y_range
    @info "Coordinates (microns):" x y
    
    # Get standard deviations from emitters if available
    first_emitter = first(smld.emitters)
    if hasfield(typeof(first_emitter), :σ_x) && hasfield(typeof(first_emitter), :σ_y)
        σ_x = [e.σ_x for e in smld.emitters]
        σ_y = [e.σ_y for e in smld.emitters]
    else
        # Use default standard deviation if not provided
        @warn "No standard deviations found in emitters, using default value of 1.0"
        σ_x = fill(1.0, length(x))
        σ_y = fill(1.0, length(y))
    end
    
    # Adjust coordinates to image coordinates - pass SMLD for pixel size
    adj_x, adj_y = adjust_coordinates(x, y, x_range, y_range, smld)
    @info "Adjusted coordinates sample:" adj_x[1:min(5,length(adj_x))] adj_y[1:min(5,length(adj_y))]
    
    # Get color map and values
    cmap = get_colormap(options.colormap)
    
    if isnothing(options.color_by)
        # Render as a single-colored image using uniform values
        gray_image = render_gaussian_blobs(
            adj_x, adj_y, σ_x, σ_y, ones(length(x)), 
            x_range, y_range;
            n_sigmas=options.n_sigmas,
            normalization=options.normalization
        )
        
        # Apply colormap and contrast adjustment
        rgb_image = apply_colormap(gray_image, cmap, 
                                  options.contrast isa NamedTuple ? 
                                  ContrastOptions(; options.contrast...) : 
                                  options.contrast)
    else
        # Get values for coloring
        values = get_color_values(smld, options.color_by)
        
        # Check if we're dealing with a 3D dataset
        is_3d = (options.color_by == :z || 
                hasfield(typeof(first_emitter), :z) ||
                (options.color_by == :depth && hasfield(typeof(first_emitter), :depth)))
        
        if is_3d
            # For 3D data, render in layers and then apply colormap
            value_range = (minimum(values), maximum(values))
            
            # Use the number of colors in the colormap as the number of layers
            n_layers = length(cmap.colors)
            
            layered_image = render_gaussian_blobs_layered(
                adj_x, adj_y, σ_x, σ_y, values, 
                x_range, y_range, n_layers, value_range;
                n_sigmas=options.n_sigmas,
                normalization=options.normalization
            )
            
            # Sum along layers to get a 2D image with weighted contributions
            weighted_sum = zeros(Float64, size(layered_image, 1), size(layered_image, 2))
            
            for layer in 1:n_layers
                weighted_sum .+= layered_image[:, :, layer] * layer
            end
            
            # Normalize and apply colormap
            if maximum(weighted_sum) > 0
                weighted_sum ./= maximum(weighted_sum)
            end
            rgb_image = apply_colormap(weighted_sum, cmap, options.contrast)
        else
            # Map values to colors
            colors = map_values_to_colormap(values, cmap, nothing)
            
            # Render colored blobs
            rgb_array = render_gaussian_blobs_colored(
                adj_x, adj_y, σ_x, σ_y, colors, 
                x_range, y_range;
                n_sigmas=options.n_sigmas,
                normalization=options.normalization
            )
            
            # Apply contrast adjustment
            rgb_image = apply_colormap(rgb_array, options.contrast)
        end
    end
    
    # Convert to final output type
    if options.output_type == :image
        # For images meant for display/saving, ensure we return RGB{N0f8}
        return convert_to_image(rgb_image)
    else
        # Return raw array for further processing
        return rgb_image
    end
end

"""
    render_2d(smld::SMLMData.SMLD; kwargs...)

Render 2D SMLM data with an explicit 2D rendering mode.

# Arguments
- `smld::SMLMData.SMLD`: The SMLM data to render
- `kwargs...`: Additional arguments to pass to `render`

# Returns
- The rendered image
"""
function render_2d(smld::SMLMData.SMLD; kwargs...)
    # Force 2D rendering mode (ignore z values)
    if !isempty(smld.emitters) && hasfield(typeof(first(smld.emitters)), :z)
        @info "Rendering 3D data in 2D mode (ignoring z values)"
    end
    return render(smld; kwargs...)
end

"""
    render_3d(smld::SMLMData.SMLD; color_by::Symbol=:z, kwargs...)

Render 3D SMLM data with z-based coloring by default.

# Arguments
- `smld::SMLMData.SMLD`: The SMLM data to render
- `color_by::Symbol=:z`: The field to use for coloring (defaults to z)
- `kwargs...`: Additional arguments to pass to `render`

# Returns
- The rendered image
"""
function render_3d(smld::SMLMData.SMLD; color_by::Symbol=:z, kwargs...)
    # Check if this is actually 3D data
    if !isempty(smld.emitters) && !hasfield(typeof(first(smld.emitters)), :z)
        @warn "Data appears to be 2D but render_3d was called. Defaulting to regular rendering."
        return render(smld; kwargs...)
    end
    
    # Use z for coloring by default
    return render(smld; color_by=color_by, kwargs...)
end

# Export interface functions
export render, render_2d, render_3d