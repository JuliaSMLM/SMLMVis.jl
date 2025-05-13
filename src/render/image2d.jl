# Implementation of 2D rendering functions

"""
    render(smld::SMLD; 
          zoom::Integer = 20,
          color_by::Symbol = :intensity,
          colormap::Union{Symbol, Nothing} = nothing,
          contrast::NamedTuple = (method=:linear, clip=0.995),
          output::Symbol = :array)

High-level function to render SMLM localization data as a 2D super-resolution image.
Uses the camera information in smld and the zoom factor to determine the pixel size.

# Arguments
- `smld`: SMLD object containing localization data
- `zoom`: Integer scaling factor for the camera pixel size (default=20)
- `color_by`: Field to use for coloring (default=:intensity)
- `colormap`: Colormap to apply (default=nothing, returns grayscale)
- `contrast`: Contrast adjustment parameters (default=(method=:linear, clip=0.995))
- `output`: Output format (:array, :colormap, or :both)

# Returns
- If output=:array: Matrix{Float32} with intensity values
- If output=:colormap: Matrix{RGB} with colored pixels
- If output=:both: Tuple of (Matrix{Float32}, Matrix{RGB})

# Example
```julia
using SMLMVis, SMLMData

# Load SMLM data
smld = SMLD2D(...) # Your SMLD data

# Render with default parameters (zoom=20)
img = render(smld)

# Render with custom parameters and colormap
img_color = render(smld, zoom=40, color_by=:z, colormap=:inferno, output=:colormap)
```
"""
function render(smld::SMLD; 
               zoom::Integer = 20,
               color_by::Symbol = :intensity,
               colormap::Union{Symbol, Nothing} = nothing,
               contrast::NamedTuple = (method=:linear, clip=0.995),
               output::Symbol = :array)
    
    # Check if camera information is available
    if !isdefined(smld, :datasize) || isempty(smld.datasize)
        # If no camera info, use data extents with a default pixel size
        xmin, xmax = extrema(smld.x)
        ymin, ymax = extrema(smld.y)
        
        # Add padding
        xpad = (xmax - xmin) * 0.05
        ypad = (ymax - ymin) * 0.05
        
        xmin -= xpad
        xmax += xpad
        ymin -= ypad
        ymax += ypad
        
        # Calculate pixel edges with default camera pixel size of 0.1 μm (100 nm)
        camera_pixel_size = 0.1  # μm
        rendered_pixel_size = camera_pixel_size / zoom
        
        # Calculate pixel edges
        pixel_edges_x = range(xmin, xmax, step=rendered_pixel_size)
        pixel_edges_y = range(ymin, ymax, step=rendered_pixel_size)
    else
        # Use camera information
        width, height = smld.datasize[1:2]
        
        # Default camera pixel size if not specified (100 nm = 0.1 μm)
        camera_pixel_size = 0.1  # μm
        
        # Calculate rendered pixel size
        rendered_pixel_size = camera_pixel_size / zoom  # in μm
        
        # Calculate pixel edges (camera coordinates start at 0,0)
        pixel_edges_x = range(0, width * camera_pixel_size, step=rendered_pixel_size)
        pixel_edges_y = range(0, height * camera_pixel_size, step=rendered_pixel_size)
    end
    
    # Call the lower-level render function
    return render(smld, pixel_edges_x, pixel_edges_y; 
                 color_by=color_by, 
                 colormap=colormap, 
                 contrast=contrast, 
                 output=output)
end

"""
    render(smld::SMLD, pixel_edges_x::AbstractVector, pixel_edges_y::AbstractVector; 
          color_by::Symbol = :intensity,
          colormap::Union{Symbol, Nothing} = nothing,
          contrast::NamedTuple = (method=:linear, clip=0.995),
          output::Symbol = :array)

Mid-level function to render SMLM localization data with specified pixel edges.

# Arguments
- `smld`: SMLD object containing localization data
- `pixel_edges_x`: X-coordinate edges for pixels (in μm)
- `pixel_edges_y`: Y-coordinate edges for pixels (in μm)
- `color_by`: Field to use for coloring (default=:intensity)
- `colormap`: Colormap to apply (default=nothing, returns grayscale)
- `contrast`: Contrast adjustment parameters (default=(method=:linear, clip=0.995))
- `output`: Output format (:array, :colormap, or :both)

# Returns
- Depending on `output` parameter (see high-level render function)
"""
function render(smld::SMLD, 
               pixel_edges_x::AbstractVector, 
               pixel_edges_y::AbstractVector;
               color_by::Symbol = :intensity,
               colormap::Union{Symbol, Nothing} = nothing,
               contrast::NamedTuple = (method=:linear, clip=0.995),
               output::Symbol = :array)
    
    # Calculate image dimensions
    height = length(pixel_edges_y) - 1
    width = length(pixel_edges_x) - 1
    
    # Create output image array
    img = zeros(Float32, height, width)
    
    # Calculate pixel centers and widths
    pixel_centers_x = 0.5 .* (pixel_edges_x[1:end-1] .+ pixel_edges_x[2:end])
    pixel_centers_y = 0.5 .* (pixel_edges_y[1:end-1] .+ pixel_edges_y[2:end])
    pixel_width_x = pixel_edges_x[2] - pixel_edges_x[1]
    pixel_width_y = pixel_edges_y[2] - pixel_edges_y[1]
    
    # Create color array if needed
    if color_by != :intensity && color_by != :photons
        color_values = _extract_color_values(smld, color_by)
    end
    
    # For each localization
    for i in 1:length(smld.x)
        # Get coordinates
        x, y = smld.x[i], smld.y[i]
        
        # Skip if outside pixel edges
        if x < pixel_edges_x[1] || x > pixel_edges_x[end] || 
           y < pixel_edges_y[1] || y > pixel_edges_y[end]
            continue
        end
        
        # Get sigma values in μm
        # Make sure σ_x and σ_y are available, otherwise use default value
        if isdefined(smld, :σ_x) && isdefined(smld, :σ_y) && i <= length(smld.σ_x)
            σx = smld.σ_x[i]
            σy = smld.σ_y[i]
        else
            # Default value if sigmas are not available (half pixel width)
            σx = σy = pixel_width_x / 2
        end
        
        # Check for photons field for intensity
        intensity = 1.0
        if isdefined(smld, :photons) && i <= length(smld.photons)
            intensity = smld.photons[i]
        end
        
        # Find pixel indices for this localization
        # Use 3-sigma range for the Gaussian
        # Convert sigmas to pixel units for range calculation
        σx_px = σx / pixel_width_x
        σy_px = σy / pixel_width_y
        
        # Find pixel indices that fall within 3 sigma of this localization
        x_idx = searchsortedlast(pixel_edges_x, x)
        y_idx = searchsortedlast(pixel_edges_y, y)
        
        # Calculate range in pixel space (3-sigma from center)
        x_range = max(1, x_idx - ceil(Int, 3 * σx_px)):min(width, x_idx + ceil(Int, 3 * σx_px))
        y_range = max(1, y_idx - ceil(Int, 3 * σy_px)):min(height, y_idx + ceil(Int, 3 * σy_px))
        
        # Skip if range is empty
        if isempty(x_range) || isempty(y_range)
            continue
        end
        
        # Render Gaussian for this localization
        for y_idx in y_range
            py = pixel_centers_y[y_idx]
            for x_idx in x_range
                px = pixel_centers_x[x_idx]
                
                # Calculate Gaussian value
                dx = (px - x) / σx
                dy = (py - y) / σy
                g = exp(-0.5 * (dx^2 + dy^2))
                
                # Add to image with intensity
                img[y_idx, x_idx] += g * intensity
            end
        end
    end
    
    # Apply contrast adjustment
    img = _adjust_contrast(img, contrast)
    
    # Return based on output format
    if output == :array
        return img
    elseif output == :colormap && colormap !== nothing
        return apply_colormap(img, colormap)
    elseif output == :both && colormap !== nothing
        return (img, apply_colormap(img, colormap))
    elseif colormap !== nothing
        return apply_colormap(img, colormap)
    else
        return img
    end
end

"""
    _extract_color_values(smld::SMLD, color_by::Symbol)

Extract values from SMLD to use for coloring.
"""
function _extract_color_values(smld::SMLD, color_by::Symbol)
    if color_by == :z && isdefined(smld, :z)
        return smld.z
    elseif color_by == :frame || color_by == :framenum
        return smld.framenum
    elseif color_by == :uncertainty
        # Use mean of x and y uncertainties
        if isdefined(smld, :σ_x) && isdefined(smld, :σ_y)
            return 0.5 .* (smld.σ_x .+ smld.σ_y)
        else
            error("Uncertainty data not available for coloring")
        end
    elseif color_by == :bg && isdefined(smld, :bg)
        return smld.bg
    else
        error("Color field '$color_by' not found or not supported")
    end
end

"""
    _adjust_contrast(img::AbstractMatrix, contrast::NamedTuple)

Adjust image contrast based on specified parameters.
"""
function _adjust_contrast(img::AbstractMatrix, contrast::NamedTuple)
    method = get(contrast, :method, :linear)
    clip = get(contrast, :clip, 0.995)
    range_min = get(contrast, :min, nothing)
    range_max = get(contrast, :max, nothing)
    
    # Determine min/max values
    if range_min === nothing || range_max === nothing
        if clip < 1.0
            # Calculate percentile-based clipping
            sorted_values = sort(filter(isfinite, vec(img)))
            if !isempty(sorted_values)
                n = length(sorted_values)
                if range_min === nothing
                    min_idx = max(1, round(Int, n * (1 - clip)))
                    range_min = sorted_values[min_idx]
                end
                if range_max === nothing
                    max_idx = min(n, round(Int, n * clip))
                    range_max = sorted_values[max_idx]
                end
            else
                range_min = 0.0
                range_max = 1.0
            end
        else
            # Use actual min/max
            range_min = minimum(img)
            range_max = maximum(img)
        end
    end
    
    # Ensure min != max to avoid division by zero
    if range_min ≈ range_max
        range_max = range_min + 1.0
    end
    
    # Apply contrast method
    img_out = similar(img)
    
    if method == :linear
        img_out .= clamp.((img .- range_min) ./ (range_max - range_min), 0.0, 1.0)
    elseif method == :log
        # Log scaling
        eps_val = max(range_min, 1e-10)  # Avoid log(0)
        img_scaled = max.(img, eps_val)
        log_min = log(eps_val)
        log_max = log(max(range_max, eps_val * 1.1))  # Ensure max > min
        img_out .= clamp.((log.(img_scaled) .- log_min) ./ (log_max - log_min), 0.0, 1.0)
    elseif method == :sqrt
        # Square root scaling
        img_out .= clamp.((sqrt.(max.(img .- range_min, 0.0))) ./ sqrt(range_max - range_min), 0.0, 1.0)
    elseif method == :equalize
        # Histogram equalization - use Images.jl function
        img_tmp = clamp.((img .- range_min) ./ (range_max - range_min), 0.0, 1.0)
        img_out .= Images.adjust_histogram(img_tmp, Images.Equalization(nbins=256))
    else
        error("Contrast method '$method' not supported")
    end
    
    return img_out
end

"""
    render_2d(smld::SMLD; 
             pixel_size=20.0, 
             roi=nothing, 
             colormap=:viridis)

Legacy function for render_2d, now uses the new render function internally.

# Arguments
- `smld`: SMLD object containing localization data
- `pixel_size`: Size of pixels in the rendered image (in same units as localization data)
- `roi`: Optional region of interest [ymin, xmin, ymax, xmax] (same units as localization data)
- `colormap`: Colormap to apply (returns RGB image if specified)

# Returns
- Rendered 2D image as Matrix{Float32} or RGB image if colormap is specified
"""
function render_2d(smld::SMLD; 
                  pixel_size::Real = 20.0,
                  roi::Union{Nothing, Vector{<:Real}} = nothing,
                  colormap::Union{Symbol, Nothing} = nothing)
    
    # Calculate pixel edges based on ROI or data extents
    if roi === nothing
        # Use data extents
        xmin, xmax = extrema(smld.x)
        ymin, ymax = extrema(smld.y)
        
        # Add padding
        xpad = (xmax - xmin) * 0.05
        ypad = (ymax - ymin) * 0.05
        
        xmin -= xpad
        xmax += xpad
        ymin -= ypad
        ymax += ypad
    else
        # Use specified ROI
        ymin, xmin, ymax, xmax = roi
    end
    
    # Calculate pixel edges
    pixel_edges_x = range(xmin, xmax, step=pixel_size)
    pixel_edges_y = range(ymin, ymax, step=pixel_size)
    
    # Call the new render function
    output = colormap === nothing ? :array : :colormap
    return render(smld, pixel_edges_x, pixel_edges_y; colormap=colormap, output=output)
end