

function quantile_clamp!(im::AbstractArray{<:Real}, percentile_cutoff::Real)
    max_val = quantile(im[im.>0], percentile_cutoff)
    im ./= max_val
    clamp!(im, 0, 1)
    return nothing
end


function gen_blob!(patch::ImagePatch2D, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol; zoom::Int=1)
    zoom_σ_x = zoom * σ_x
    zoom_σ_y = zoom * σ_y
    inv_2σx2 = 1 / (2 * zoom_σ_x^2)
    inv_2σy2 = 1 / (2 * zoom_σ_y^2)
    x_zoom = x * zoom
    y_zoom = y * zoom

    for i in CartesianIndices(patch.roi)
        y_i, x_i = Tuple(i)
        adjusted_x_i = x_i + patch.offset_x
        adjusted_y_i = y_i + patch.offset_y
        patch.roi[i] = exp(-((adjusted_x_i - x_zoom)^2 * inv_2σx2 + (adjusted_y_i - y_zoom)^2 * inv_2σy2))
    end

    if normalization == :integral
        patch.roi .= patch.roi ./ (sum(patch.roi) + eps())
    elseif normalization == :maximum
        patch.roi .= patch.roi ./ maximum(patch.roi + eps())
    end
end

function add_blob!(image::AbstractArray{<:Real}, patch::ImagePatch2D, offset_x::Int, offset_y::Int)
    for idx in CartesianIndices(patch.roi)
        global_idx = idx + CartesianIndex(patch.offset_y, patch.offset_x) - CartesianIndex(offset_y, offset_x)
        global_y, global_x = Tuple(global_idx)
        image[global_y, global_x] += patch.roi[idx]
    end
end

function add_blob!(image::ImagePatch2D, patch::ImagePatch2D)
    add_blob!(image.roi, patch, image.offset_x, image.offset_y)
end

function add_blobs!(image::ImagePatch2D{T}, patches::Vector{ImagePatch2D{T}}) where {T<:Real}
    Threads.@threads for patch in patches
        add_blob!(image, patch)
    end
end

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

