

function create_colormap(z, colormap)
    if isnothing(z) && isnothing(colormap)
        ColorSchemes.hot
    elseif !isnothing(z) && isnothing(colormap)
        ColorSchemes.rainbow_bgyr_35_85_c72_n256
    else
        getfield(ColorSchemes, colormap)
    end
end

function apply_colormap_to_image(gray_image::ImagePatch2D, cmap, percentile_cutoff)
    quantile_clamp!(gray_image.roi, percentile_cutoff)
    get(cmap, gray_image.roi)
end

function apply_colormap_to_image(gray_image::ImagePatch3D, cmap::ColorScheme, percentile_cutoff)
    # Dimensions of the gray_image
    height, width, layers = size(gray_image.roi)

    # Preallocate the final RGB image
    final_image = Array{RGB{Float64}}(undef, height, width)

    # Initialize accumulators for r, g, b values
    r_sum = zeros(height, width)
    g_sum = zeros(height, width)
    b_sum = zeros(height, width)

    # Accumulate color values directly
    Threads.@threads for i in 1:layers
        r_sum .+= cmap[i].r .* view(gray_image.roi, :, :, i)
        g_sum .+= cmap[i].g .* view(gray_image.roi, :, :, i)
        b_sum .+= cmap[i].b .* view(gray_image.roi, :, :, i)
    end


    max_val = max(
        any(r_sum .> 0) ? quantile(r_sum[r_sum.>0], percentile_cutoff) : 0,
        any(g_sum .> 0) ? quantile(g_sum[g_sum.>0], percentile_cutoff) : 0,
        any(b_sum .> 0) ? quantile(b_sum[b_sum.>0], percentile_cutoff) : 0
    )

    r_sum ./= max_val
    g_sum ./= max_val
    b_sum ./= max_val

    clamp!(r_sum, 0, 1)
    clamp!(g_sum, 0, 1)
    clamp!(b_sum, 0, 1)

    final_image = RGB.(r_sum, g_sum, b_sum)
    
end

