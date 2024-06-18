"""
    create_colormap(z, colormap)

Determine the best colormap to use based on the provided z and colormap parameters.

If both z and colormap are nothing, the function returns the 'hot' colormap. If z is provided and 
colormap is nothing, the function returns the 'rainbow_bgyr_35_85_c72_n256' colormap. If colormap is provided, 
it returns the specified colormap from ColorSchemes.
# Arguments
- `z`                : A parameter that can influence the colormap selection.
- `colormap`         : A string representing the desired colormap from ColorSchemes.

# Returns
- A colormap from ColorSchemes.
"""
function create_colormap(z, colormap)
    if isnothing(z) && isnothing(colormap)
        ColorSchemes.hot
    elseif !isnothing(z) && isnothing(colormap)
        ColorSchemes.rainbow_bgyr_35_85_c72_n256
    else
        getfield(ColorSchemes, colormap)
    end
end

"""
    apply_colormap_to_image(gray_image::ImagePatch2D, cmap, percentile_cutoff)

Apply a colormap to a 2D grayscale image patch after clamping its intensity values.

Clamps the intensity values of the grayscale image patch based on the specified percentile cutoff, and then applies the given colormap.
# Arguments
- `gray_image::ImagePatch2D`            : The input 2D grayscale image patch.
- `cmap`                                : The colormap to be applied.
- `percentile_cutoff`                   : The percentile cutoff for intensity clamping.

# Returns
- An image with the colormap applied.
"""
function apply_colormap_to_image(gray_image::ImagePatch2D, cmap, percentile_cutoff)
    quantile_clamp!(gray_image.roi, percentile_cutoff)
    get(cmap, gray_image.roi)
end

"""
    apply_colormap_to_image(gray_image::ImagePatch3D, cmap::ColorScheme, percentile_cutoff)

Applies a colormap to a 3D image patch, processing each layer to apply RGB values based on the provided color map and normalizes these values using a specified percentile cutoff.

# Arguments
- `gray_image::ImagePatch3D`: The 3D image patch to process.
- `cmap::ColorScheme`: The color map to apply, where each layer's RGB values are mapped individually.
- `percentile_cutoff`: The percentile for normalizing the accumulated RGB values.

# Detailed Process
1. Calculate the RGB values for each layer of the image.
2. Normalize these RGB values across all layers using the highest value found by the given percentile.
3. Clamp the RGB values to ensure they fall within the valid range of 0 to 1.

# Returns
- Returns a color-mapped 3D image where each pixel is represented as an RGB value.

# Example
```julia
apply_colormap_to_image(image_patch_3d, cmap, 0.95)
```
"""

"""
    apply_colormap_to_image(gray_image::ImagePatch3D, cmap::ColorScheme, percentile_cutoff)

Applies a colormap to a 3D grayscale image patch after clamping its intensity values.

# Arguments
- `gray_image::ImagePatch3D`            : The input 3D grayscale image patch.
- `cmap::ColorScheme`                   : The colormap to be applied.
- `percentile_cutoff`                   : The percentile cutoff for intensity clamping.

# Returns
- An RGB image with the colormap applied.

# Description
Clamps the intensity values of each layer in the 3D grayscale image patch based on the specified percentile cutoff, and then applies the given colormap. 
The final RGB image is constructed by accumulating the color values from each layer.
"""
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
    return final_image
    
end

