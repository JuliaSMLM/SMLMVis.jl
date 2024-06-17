"""Documentation for the `gauss_render.blobrender` module."""
"""
    quantile_clamp!(im, percentile_cutoff)

# Description   
    
    a function to clamp the intensity values of an image based on the specified percentile cutoff.  
    

# Arguments 
- `im::AbstractArray{<:Real}` : The input image, a 2D array of real numbers.
- `percentile_cutoff::Real`   : The percentile cutoff for intensity clamping.

# return nothing

"""

function quantile_clamp!(im::AbstractArray{<:Real}, percentile_cutoff::Real)
    max_val = quantile(im[im.>0], percentile_cutoff)
    im ./= max_val
    clamp!(im, 0, 1)
    return nothing
end

"""
    gen_blob!(patch, x, y, σ_x, σ_y:, normalization; zoom=1)

# Description
    
        Generates a 2D Gaussian blob centered at (x, y) with standard deviations σ_x and σ_y.    
        The blob is normalized either by its integral or maximum value.
        
# Arguments
    - `patch::ImagePatch2D` : The image patch to store the generated blob.
    - `x::Real`              : The x-coordinate of the blob center.
    - `y::Real`              : The y-coordinate of the blob center.
    - `σ_x::Real`            : The standard deviation of the blob along the x-axis.
    - `σ_y::Real`            : The standard deviation of the blob along the y-axis.
    - `normalization::Symbol`: The normalization method, either `:integral` or `:maximum`.
    - `zoom::Int`            : The zoom factor for the blob. Default is 1.
 
# Returns

    - The generated blob is stored in the `patch` argument.

    """

function gen_blob!(patch::ImagePatch2D, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol; zoom::Int=1)
    # Calculate the zoomed standard deviations
    zoom_σ_x = zoom * σ_x  
    zoom_σ_y = zoom * σ_y
    inv_2σx2 = 1 / (2 * zoom_σ_x^2)
    inv_2σy2 = 1 / (2 * zoom_σ_y^2)
    x_zoom = x * zoom
    y_zoom = y * zoom
    # Generate the blob using the 2D Gaussian function
    for i in CartesianIndices(patch.roi)  # CartesianIndices iterates over the indices of the array. Useful for 2D and 3D abstract arrays.
        y_i, x_i = Tuple(i)
        adjusted_x_i = x_i + patch.offset_x
        adjusted_y_i = y_i + patch.offset_y
        patch.roi[i] = exp(-((adjusted_x_i - x_zoom)^2 * inv_2σx2 + (adjusted_y_i - y_zoom)^2 * inv_2σy2))
    end
    # Normalize the blob
    if normalization == :integral
        patch.roi .= patch.roi ./ (sum(patch.roi) + eps())
    elseif normalization == :maximum
        patch.roi .= patch.roi ./ maximum(patch.roi + eps())
    end
end

"""
    add_blobs!(image, patches)

# Description
    
        Adds multiple blobs to an image patch.

# Arguments
    - `image::ImagePatch2D` : The image patch to which the blobs will be added.
    - `patches::Vector{ImagePatch2D}` : A vector of image patches to be added to the image.

# Returns
    
        - The image patch with the added blobs.
    
"""

function add_blobs!(image::ImagePatch2D{T}, patches::Vector{ImagePatch2D{T}}) where {T<:Real}
    Threads.@threads for patch in patches
        add_blobs!(image, patch)
    end
end

"""

    add_blobs!(image, patches, cmap, z_range)

# Description
    
        Adds multiple blobs to a 3D image patch with different z-values and applies a colormap to the blobs.

# Arguments
    - `image::ImagePatch3D` : The 3D image patch to which the blobs will be added.
    - `patches::Vector{ImagePatch2D}` : A vector of 2D image patches to be added to the image.
    - `cmap::ColorScheme` : The colormap to be applied to the blobs.
    - `z_range::Tuple{Real,Real}` : The range of z-values for the colormap.

# Returns

        """
function add_blobs!(image::ImagePatch3D{T}, patches::Vector{ImagePatch2D{T}}, cmap::ColorScheme, z_range::Tuple{Real,Real}) where {T<:Real}
    cmap_length = length(cmap.colors)

    Threads.@threads for patch in patches
        # Calculate z-index based on the patch's z value
        z_idx = Int(floor((patch.z - z_range[1]) / (z_range[2] - z_range[1]) * cmap_length)) + 1

        # Check if z_idx is within the valid range
        if z_idx < 1 || z_idx > cmap_length
            continue
        end

        # Create a view of the image at the calculated z-index
        layer_view = view(image.roi, :, :, z_idx)

        # Add the patch to the specific layer of the image
        add_blob!(layer_view, patch, image.offset_x, image.offset_y)        
    end
end

