# Utility functions for rendering

using Images
using SMLMData

"""
    calculate_pixel_edges(smld::SMLMData.SMLD, zoom::Integer)

Calculate pixel edges for rendering an SMLD object with the specified zoom factor.

# Arguments
- `smld::SMLMData.SMLD`: The SMLD object with camera information
- `zoom::Integer`: The zoom factor to apply to the pixel size

# Returns
- `x_edges::Vector{Int}`: The x-coordinates of the pixel edges
- `y_edges::Vector{Int}`: The y-coordinates of the pixel edges
"""
function calculate_pixel_edges(smld::SMLMData.SMLD, zoom::Integer)
    # Check if camera is available
    if isdefined(smld, :camera) && !isnothing(smld.camera)
        # Get pixel edges from camera
        if isdefined(smld.camera, :pixel_edges_x) && 
           isdefined(smld.camera, :pixel_edges_y)
            
            # Get pixel edges directly from the camera
            pixel_edges_x = smld.camera.pixel_edges_x
            pixel_edges_y = smld.camera.pixel_edges_y
            
            # Calculate pixel size from edges
            pixel_size_x = mean(diff(pixel_edges_x))
            pixel_size_y = mean(diff(pixel_edges_y))
            
            # Calculate width and height in pixels
            width = length(pixel_edges_x) - 1
            height = length(pixel_edges_y) - 1
            
            @info "Camera dimensions:" width height
            @info "Camera pixel size:" pixel_size_x pixel_size_y
            
            # Create high-resolution pixel edges with zoom factor
            zoomed_width = width * zoom
            zoomed_height = height * zoom
            
            # Create zoomed pixel edges
            x_edges = 1:(zoomed_width)
            y_edges = 1:(zoomed_height)
            
            @info "Using camera information for pixel edges. Zoomed dimensions: $zoomed_width x $zoomed_height"
            
            return x_edges, y_edges
        end
    end
    
    # If proper camera information is not available, estimate from emitters
    if !isempty(smld.emitters)
        # Get coordinate extremes from emitters
        x_vals = [e.x for e in smld.emitters]
        y_vals = [e.y for e in smld.emitters]
        
        min_x, max_x = extrema(x_vals)
        min_y, max_y = extrema(y_vals)
        
        # Estimate pixel size (assume 100nm = 0.1μm if not specified)
        pixel_size = 0.1  # Default pixel size in microns
        
        # Calculate dimensions, with some padding
        padding = 0.1  # 10% padding on each side
        padded_width = (max_x - min_x) * (1 + 2 * padding)
        padded_height = (max_y - min_y) * (1 + 2 * padding)
        
        # Calculate number of pixels, ensuring at least 1 pixel
        width = max(1, ceil(Int, padded_width / pixel_size))
        height = max(1, ceil(Int, padded_height / pixel_size))
        
        # Create zoomed pixel edges
        x_edges = 1:(width*zoom)
        y_edges = 1:(height*zoom)
        
        @info "Estimated pixel edges from emitters: $(width*zoom) x $(height*zoom)"
        @info "Emitter range: $min_x-$max_x, $min_y-$max_y microns"
        
        return x_edges, y_edges
    end
    
    # Fallback to a default size if all else fails
    @warn "No camera or emitter information available, using default size of 100x100"
    width = height = 100
    x_edges = 1:(width*zoom)
    y_edges = 1:(height*zoom)
    
    return x_edges, y_edges
end

"""
    pixel_repeat(array::AbstractArray{T,2}, zoom::Integer) where T

Resample a 2D array by repeating each pixel a specified number of times.

# Arguments
- `array::AbstractArray{T,2}`: The input array to resample
- `zoom::Integer`: The zoom factor to apply

# Returns
- `Array{T,2}`: The resampled array
"""
function pixel_repeat(array::AbstractArray{T,2}, zoom::Integer) where T
    height, width = size(array)
    
    # Create an indexing array for each dimension that repeats each index zoom times
    row_indices = repeat(1:height, inner=zoom)
    col_indices = repeat(1:width, inner=zoom)
    
    # Use indexing to create the zoomed array
    zoomed_array = array[row_indices, col_indices]
    
    return zoomed_array
end

"""
    convert_to_image(array::AbstractArray{T,2}) where T <: Real

Convert a 2D array of real values to a Gray image.

# Arguments
- `array::AbstractArray{T,2}`: The input array to convert

# Returns
- `Array{Gray{N0f8},2}`: The converted image
"""
function convert_to_image(array::AbstractArray{T,2}) where T <: Real
    # Normalize the array to 0-1 range
    min_val = minimum(array)
    max_val = maximum(array)
    
    # Handle case where all values are the same
    if min_val == max_val
        normalized = fill(Gray{N0f8}(0.5), size(array))
    else
        normalized = Gray{N0f8}.((array .- min_val) ./ (max_val - min_val))
    end
    
    return normalized
end

"""
    convert_to_image(rgb_image::Array{RGB{T},2}) where T <: Real

Convert an RGB image to a format suitable for display or saving (8-bit RGB).

# Arguments
- `rgb_image::Array{RGB{T},2}`: The input RGB image

# Returns
- `Array{RGB{N0f8},2}`: The converted 8-bit RGB image
"""
function convert_to_image(rgb_image::Array{RGB{T},2}) where T <: Real
    # Ensure all RGB values are in 0-1 range before converting to N0f8
    rgb_clamped = clamp.(rgb_image, 0.0, 1.0)
    
    # Convert to 8-bit RGB format (N0f8)
    return RGB{N0f8}.(rgb_clamped)
end

"""
    save_image(filename::AbstractString, image::Array)

Save an image to a file.

# Arguments
- `filename::AbstractString`: The name of the output file
- `image::Array`: The image to save
"""
function save_image(filename::AbstractString, image::Array)
    # For PNG files, make sure we're using RGB{N0f8}
    if endswith(lowercase(filename), ".png") && eltype(image) <: RGB && !(eltype(image) <: RGB{N0f8})
        image_to_save = convert_to_image(image)
    else
        image_to_save = image
    end
    
    save(filename, image_to_save)
end

"""
    ranges_to_indices(x_range::Tuple{Real,Real}, y_range::Tuple{Real,Real})

Convert coordinate ranges to arrays of indices.

# Arguments
- `x_range::Tuple{Real,Real}`: The range of x-coordinates
- `y_range::Tuple{Real,Real}`: The range of y-coordinates

# Returns
- `x_indices::UnitRange{Int}`: The x-indices for the image
- `y_indices::UnitRange{Int}`: The y-indices for the image
"""
function ranges_to_indices(x_range::Tuple{Real,Real}, y_range::Tuple{Real,Real})
    x_start, x_end = x_range
    y_start, y_end = y_range
    
    x_indices = Int(floor(x_start)):Int(ceil(x_end))
    y_indices = Int(floor(y_start)):Int(ceil(y_end))
    
    return x_indices, y_indices
end

"""
    adjust_coordinates(x::AbstractVector{<:Real}, 
                      y::AbstractVector{<:Real}, 
                      x_range::Tuple{Real,Real}, 
                      y_range::Tuple{Real,Real},
                      smld::Union{SMLMData.SMLD, Nothing}=nothing)

Adjust coordinates relative to the specified ranges.
Assumes x and y are in microns and need to be converted to pixel coordinates.

# Arguments
- `x::AbstractVector{<:Real}`: The x-coordinates in microns
- `y::AbstractVector{<:Real}`: The y-coordinates in microns
- `x_range::Tuple{Real,Real}`: The range of valid x pixel coordinates
- `y_range::Tuple{Real,Real}`: The range of valid y pixel coordinates
- `smld::Union{SMLMData.SMLD, Nothing}`: Optional SMLD object to get pixel size

# Returns
- `adjusted_x::Vector{Float64}`: The adjusted x-coordinates in pixels
- `adjusted_y::Vector{Float64}`: The adjusted y-coordinates in pixels
"""
function adjust_coordinates(x::AbstractVector{<:Real}, 
                           y::AbstractVector{<:Real}, 
                           x_range::Tuple{Real,Real}, 
                           y_range::Tuple{Real,Real},
                           smld::Union{SMLMData.SMLD, Nothing}=nothing)
    
    # Determine pixel size - try to get from SMLD camera, otherwise use default
    pixel_size = 0.1  # default 100 nm pixels
    
    if !isnothing(smld) && isdefined(smld, :camera) && !isnothing(smld.camera) &&
       isdefined(smld.camera, :pixel_edges_x) && length(smld.camera.pixel_edges_x) > 1
        # Calculate pixel size from camera
        pixel_size = mean(diff(smld.camera.pixel_edges_x))
        @info "Using pixel size from camera: $pixel_size microns"
    else
        @info "Using default pixel size: $pixel_size microns"
    end
    
    # Convert from microns to pixels using standard SMLMData conversion
    # For proper conversion, we'd use:
    # pixel_coords = [SMLMData.physical_to_pixel(x[i], y[i], pixel_size) for i in 1:length(x)]
    # pixel_x = [p[1] for p in pixel_coords]
    # pixel_y = [p[2] for p in pixel_coords]
    
    # This is the direct implementation of physical_to_pixel
    pixel_x = (x ./ pixel_size) .+ 1.0 
    pixel_y = (y ./ pixel_size) .+ 1.0
    
    # Calculate the width/height of the output image in pixels
    width = x_range[2] - x_range[1] + 1
    height = y_range[2] - y_range[1] + 1
    
    # For camera-based data, we should map directly to the camera coordinates
    if !isnothing(smld) && isdefined(smld, :camera) && !isnothing(smld.camera) &&
       isdefined(smld.camera, :pixel_edges_x) && isdefined(smld.camera, :pixel_edges_y)
        
        # Get camera dimensions from pixel edges
        camera_width = length(smld.camera.pixel_edges_x) - 1
        camera_height = length(smld.camera.pixel_edges_y) - 1
        output_width = x_range[2] - x_range[1] + 1
        output_height = y_range[2] - y_range[1] + 1
        
        # Calculate scale factor from camera to output dimensions
        scale_x = output_width / camera_width
        scale_y = output_height / camera_height
        
        # Direct mapping with stretching to fill the output area
        # We use a direct linear mapping from camera pixel coordinates to output coordinates
        adjusted_x = x_range[1] .+ (pixel_x .- 1.0) .* scale_x
        adjusted_y = y_range[1] .+ (pixel_y .- 1.0) .* scale_y
        
        @info "Using direct camera mapping, scales: $scale_x, $scale_y"
    else
        # For non-camera data, use centered scaling with minimal margins
        min_x, max_x = extrema(pixel_x)
        min_y, max_y = extrema(pixel_y)
        data_width = max_x - min_x
        data_height = max_y - min_y
        
        # Calculate the image center and dimensions
        center_img_x = (x_range[1] + x_range[2]) / 2
        center_img_y = (y_range[1] + y_range[2]) / 2
        img_width = x_range[2] - x_range[1] + 1
        img_height = y_range[2] - y_range[1] + 1
        
        # Calculate the data center
        center_data_x = (min_x + max_x) / 2
        center_data_y = (min_y + max_y) / 2
        
        # Calculate scaling to fill image with minimal margin
        margin = 0.01  # 1% margin on each side
        margin_px_x = img_width * margin
        margin_px_y = img_height * margin
        visible_width = img_width - 2 * margin_px_x
        visible_height = img_height - 2 * margin_px_y
        
        # Calculate scale factor (use smaller to maintain aspect ratio)
        scale_x = visible_width / max(data_width, 1.0)
        scale_y = visible_height / max(data_height, 1.0)
        scale = min(scale_x, scale_y)
        
        # Apply centering and scaling
        adjusted_x = center_img_x .+ (pixel_x .- center_data_x) .* scale
        adjusted_y = center_img_y .+ (pixel_y .- center_data_y) .* scale
        
        @info "Using centered scaling with minimal margins: scale=$scale"
    end
    
    # Debug info was already output in each branch
    
    # Debug output
    # Print a sample of coordinates for debugging
    sample_size = min(5, length(x))
    @info "Coordinate adjustment sample:" data_x=x[1:sample_size] data_y=y[1:sample_size]
    @info "Pixels before adjustment sample:" pixel_x[1:sample_size] pixel_y[1:sample_size]
    @info "Pixels after adjustment sample:" adjusted_x[1:sample_size] adjusted_y[1:sample_size]
    @info "Image dimensions:" width height
    
    return adjusted_x, adjusted_y
end

# Export utility functions
export calculate_pixel_edges, pixel_repeat
export convert_to_image, save_image
export ranges_to_indices, adjust_coordinates