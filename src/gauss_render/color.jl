"""
    create_colormap(z, colormap)

Create and return a color scheme based on specified parameters.

# Arguments
- `z`: Optional. Specifies if a specific z-index is considered.
- `colormap`: Optional. The name of the colormap to use from `ColorSchemes`.

# Returns
- Returns a `ColorScheme` object based on the input parameters. If no parameters are provided, it defaults to the `hot` color scheme.

# Example
```julia
cmap = create_colormap(z, :hot)
```
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

Applies a colormap to a 2D image patch after normalizing the image data based on a percentile cutoff.

# Arguments
- `gray_image::ImagePatch2D`: The 2D image patch to process.
- `cmap`: The color map to apply.
- `percentile_cutoff`: The percentile used for normalization, clamping the pixel values after scaling.

# Usage
```julia
apply_colormap_to_image(image_patch_2d, cmap, 0.99)
```
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

