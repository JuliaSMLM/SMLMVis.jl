

function update_final_image_with_cmap!(
    final_image::RGBArray{Float32},
    rois::Vector{OffsetArray{Float32,2}},
    cmap::ColorScheme,
    z::Vector{<:Real},
    z_range::Tuple{<:Real,<:Real}
)

    for i in 1:length(rois)
        # Calculate color based on z[i]
        z_min, z_max = z_range
        color = get(cmap, (z[i] - z_min) / (z_max - z_min))

        # Extract individual color components
        r, g, b = Float32(color.r), Float32(color.g), Float32(color.b)
        # ba = @allocated begin
        writecolor!(final_image.r.parent, final_image.r.offsets, rois[i], r)
        writecolor!(final_image.g.parent, final_image.g.offsets, rois[i], g)
        writecolor!(final_image.b.parent, final_image.b.offsets, rois[i], b)
        # end
        # println("allocated in writecolor! $ba")
    end

    return nothing
end

function quantile_clamp!(colorim::AbstractArray{RGB{<:Real}}, percentile_cutoff::Real)
    
    # Extract the color channels
    r = [color.r for color in colorim]
    g = [color.g for color in colorim]
    b = [color.b for color in colorim]

    # Compute the max_val based on the non-zero quantiles
    max_val = if any(r .> 0) || any(g .> 0) || any(b .> 0)
        max(
            any(r .> 0) ? quantile(r[r.>0], percentile_cutoff) : 0,
            any(g .> 0) ? quantile(g[g.>0], percentile_cutoff) : 0,
            any(b .> 0) ? quantile(b[b.>0], percentile_cutoff) : 0
        )
    else
        1.0  # Avoid division by zero
    end

    # Normalize the channels
    r ./= max_val
    g ./= max_val
    b ./= max_val

    # Clamp the values
    clamp!(r, 0, 1)
    clamp!(g, 0, 1)
    clamp!(b, 0, 1)

    # Write the values back to the colorim
    for i in 1:length(colorim)
        colorim[i] = RGB{Float64}(r[i], g[i], b[i])
    end

    return nothing
end

function quantile_clamp!(im::AbstractArray{<:Real}, percentile_cutoff::Real)
    max_val = quantile(im[im.>0], percentile_cutoff)
    im ./= max_val
    clamp!(im, 0, 1)
    return nothing
end


function gen_blob!(patch::ImagePatch, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol, zoom::Int=1)
    zoom_σ_x = zoom * σ_x
    zoom_σ_y = zoom * σ_y
    inv_2σx2 = 1 / (2 * zoom_σ_x^2)
    inv_2σy2 = 1 / (2 * zoom_σ_y^2)
    x_zoom = (x - patch.offset_x) * zoom
    y_zoom = (y - patch.offset_y) * zoom

    @inbounds for i in CartesianIndices(patch.roi)
        y_i, x_i = Tuple(i)
        adjusted_x_i = x_i + patch.offset_x - 1
        adjusted_y_i = y_i + patch.offset_y - 1
        patch.roi[i] = exp(-((adjusted_x_i - x_zoom)^2 * inv_2σx2 + (adjusted_y_i - y_zoom)^2 * inv_2σy2))
    end

    if normalization == :integral
        patch.roi .= patch.roi ./ sum(patch.roi)
    elseif normalization == :maximum
        patch.roi .= patch.roi ./ maximum(patch.roi)
    end
end

function add_blob!(image::ImagePatch2D, patch::ImagePatch2D)
    for idx in CartesianIndices(patch.roi)
        global_idx = idx + CartesianIndex(patch.offset_y, patch.offset_x) - CartesianIndex(image.offset_y, image.offset_x)

        # Destructure global_idx into its integer components for indexing
        global_y, global_x = Tuple(global_idx)

        if global_y >= 1 && global_y <= size(image.roi, 1) && global_x >= 1 && global_x <= size(image.roi, 2)
            image.roi[global_y, global_x] += patch.roi[idx]
        else
            println("image offset: (", image.offset_y, ", ", image.offset_x, ")")
            println("patch offset: (", patch.offset_y, ", ", patch.offset_x, ")")
            println("Patch extends beyond the image bounds at index: (", global_y, ", ", global_x, ")")
            error("Patch extends beyond the image bounds")

        end
    end
end




function add_blobs!(image::ImagePatch2D{T}, patches::Vector{ImagePatch2D{T}}) where T<:Real
    for patch in patches
        add_blob!(image, patch)
    end
end

function add_blobs!(image::ImagePatch3D, patches::Vector{ImagePatch3D}, cmap::ColorScheme, z_range::Tuple{Real,Real})
    cmap_length = length(cmap.colors)

    for patch in patches
        # Calculate z-index based on the patch's z value
        z_idx = Int(floor((patch.z - z_range[1]) / (z_range[2] - z_range[1]) * cmap_length)) + 1

        # Check if z_idx is within the valid range
        if z_idx < 1 || z_idx > cmap_length
            continue
        end

        # Create a view of the image at the calculated z-index
        layer_view = view(image.roi, :, :, z_idx)

        # Add the patch to the specific layer of the image
        add_blob!(layer_view, patch)
    end
end

