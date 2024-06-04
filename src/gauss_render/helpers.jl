"""
    calc_offset(x::Real, y::Real, box_size::Int, x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int}, zoom::Int)

Calculate the starting x- and y-coordinates of a box centered at `(x, y)` with a given size, within the specified x- and y-ranges.

# Arguments
- `x::Real`: The x-coordinate of the center of the box.
- `y::Real`: The y-coordinate of the center of the box.
- `box_size::Int`: The size of the box.
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the box.
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the box.
- `zoom::Int`: The zoom factor to apply to the box.
 
# Returns
- `x_offset::Int`: The x-coordinate of the top-left corner of the box.
- `y_offset::Int`: The y-coordinate of the top-left corner of the box.
"""

function calc_offset(x::Real, y::Real, box_size::Int, x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int}, zoom::Int)
    # Calculate the proposed start positions
    x_start_proposed = Int(floor(x * zoom - box_size / 2))
    y_start_proposed = Int(floor(y * zoom - box_size / 2))

    # Ensure the start positions are within the image bounds
    x_start = clamp(x_start_proposed, x_range[1], x_range[2] - box_size + 1)
    y_start = clamp(y_start_proposed, y_range[1], y_range[2] - box_size + 1)

    x_offset = x_start - 1
    y_offset = y_start - 1

    return x_offset, y_offset
end

function initialize_gray_image(x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int})::ImagePatch2D
    roi = zeros(y_range[2] - y_range[1] + 1, x_range[2] - x_range[1] + 1)
    ImagePatch2D(roi, x_range[1] - 1, y_range[1] - 1, 0.0)
end

function initialize_gray_image(x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int}, cmap_colors_length::Int)::ImagePatch3D
    roi = zeros(y_range[2] - y_range[1] + 1, x_range[2] - x_range[1] + 1, cmap_colors_length)
    ImagePatch3D(roi, x_range[1] - 1, y_range[1] - 1, 0.0)
end

function generate_image_patches(
    n_blobs_section,
    x_range,
    y_range,
    x,
    y,
    z,
    n_range,
    box_size,
    zoom
)
    blobs = Vector{ImagePatch2D{Float64}}(undef, n_blobs_section)
    for i in 1:n_blobs_section
        current_index = n_range[i]

        # Get the range tuple from calc_range
        offset_x, offset_y = calc_offset(x[current_index], y[current_index], box_size, x_range, y_range, zoom)

        # Create an array for roi
        roi_array = zeros(Float64, box_size, box_size)

        # Create an ImagePatch with the roi_array and calculated offsets
        z_value = isnothing(z) ? 0.0 : z[current_index]
        blobs[i] = ImagePatch2D(roi_array, offset_x, offset_y, z_value)
    end
    return blobs
end



function render_image_patches!(blobs, x, y, σ_x, σ_y, normalization, zoom, n_range, n_start)
    @info "Rendering Blobs"
    for i in n_range
        gen_blob!(blobs[i-n_start+1], x[i], y[i], σ_x[i], σ_y[i], normalization; zoom)
    end
end


function combine_image_patches!(gray_image::ImagePatch, blobs, z, cmap, z_range)
    @info "Combining rois"
    if isnothing(z)
        add_blobs!(gray_image, blobs)
    else
        add_blobs!(gray_image, blobs, cmap, z_range)
    end
end



