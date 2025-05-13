# Colormap utilities for SMLM visualization

"""
    apply_colormap(img::AbstractMatrix, colormap::Symbol=:viridis)

Apply a colormap to a grayscale image.

# Arguments
- `img`: Input grayscale image
- `colormap`: Colormap name (Symbol), defaults to :viridis

# Returns
- RGB image with the applied colormap

# Available colormaps include:
- :viridis, :plasma, :inferno, :magma - Perceptually uniform colormaps
- :turbo - Google's improved rainbow colormap
- :hot, :jet - Traditional colormaps (not perceptually uniform)
- :grays - Grayscale colormap

# Example
```julia
using SMLMVis
using Images

# Load or generate a grayscale image
img = rand(100, 100)

# Apply a colormap
colored_img = apply_colormap(img, :inferno)

# Save the result
save("colored.png", colored_img)
```
"""
function apply_colormap(img::AbstractMatrix, colormap::Symbol=:viridis)
    # Normalize if not already in 0-1 range
    if maximum(img) > 1.0 || minimum(img) < 0.0
        img_norm = clamp.((img .- minimum(img)) ./ (maximum(img) - minimum(img)), 0.0, 1.0)
    else
        img_norm = img
    end
    
    # Apply colormap
    return Images.colormap(colormap).(img_norm)
end

"""
    available_colormaps()

List all available colormaps.

# Returns
- Vector of Symbol with available colormap names
"""
function available_colormaps()
    [
        :viridis, :plasma, :inferno, :magma,  # Perceptually uniform
        :turbo,                              # Google's improved rainbow
        :hot, :jet,                          # Traditional
        :grays                               # Grayscale
    ]
end