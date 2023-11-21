

"""
    calc_range(x::Real, y::Real, box_size::Int, x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int})

Calculate the starting x- and y-coordinates of a box centered at `(x, y)` with a given size, within the specified x- and y-ranges.

# Arguments
- `x::Real`: The x-coordinate of the center of the box.
- `y::Real`: The y-coordinate of the center of the box.
- `box_size::Int`: The size of the box.
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the box.
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the box.
- `zoom::Int`: The zoom factor to apply to the box.
 
# Returns
- `y_range_roi::UnitRange{Int}`: The range of y-coordinates for the box.
- `x_range_roi::UnitRange{Int}`: The range of x-coordinates for the box.
"""
function calc_range(x::Real, y::Real, box_size::Int,
    x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int}, zoom::Int)

    # Calculate the starting x-coordinate of the box
    x_start = Int(floor(max(x * zoom - box_size / 2, x_range[1])))
    x_start = Int(floor(min(x_start, x_range[2] - box_size)))

    # Calculate the starting y-coordinate of the box
    y_start = Int(floor(max(y * zoom - box_size / 2, y_range[1])))
    y_start = Int(floor(min(y_start, y_range[2] - box_size)))

    # Create ROI ranges
    x_range_roi = x_start:(x_start+box_size-1)
    y_range_roi = y_start:(y_start+box_size-1)

    return y_range_roi, x_range_roi
end



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

function combine_rois!(final_image::RGBArray{Float32},
    rois::Vector{<:OffsetArray{Float32,2}},
    cmap::ColorScheme;
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
)

    if ~isnothing(z) # color is based on z
        @info "Coloring based on z"
        if isnothing(z_range)
            z_range = (minimum(z), maximum(z))
        end
        bytes_allocated = @allocated update_final_image_with_cmap!(final_image, rois, cmap, z, z_range)
        println("Bytes allocated: ", bytes_allocated)
    else
        @info "Coloring based on intensity"
        update_final_image!(final_image, rois)
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


"""
    combine_rois(rois::Vector{<:OffsetArray}, x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int};
    colormap::Union{Nothing,Symbol}=nothing,
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
    )

Combine a vector of 2D arrays into a single image, with optional colorization based on a vector of values.

# Arguments
- `rois::Vector{<:OffsetArray{Float32,2}}`: A vector of 2D arrays to combine into a single image.
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the final image.
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the final image.
- `cmap::ColorScheme`: The ColorSchemes colormap to use for colorizing the image. Valid options are `:viridis`, `:plasma`, `:inferno`, `:magma`, `:cividis`, `:rainbow_bgyr_35_85_c72_n256`, `:hot`, `:cool`, `:spring`, `:summer`, `:autumn`, `:winter`, `:bone`, `:copper`, `:pink`, `:gray`, `:binary`, `:gist_earth`, `:terrain`, `:ocean`, `:jet`, `:nipy_spectral`, `:gist_ncar`, `:gist_rainbow`, `:hsv`, `:flag`, `:prism`, `:flag_r`, `:prism_r`, `:rainbow`, `:rainbow_r`, `:seismic`, `:seismic_r`, `:brg`, `:brg_r`, `:bwr`, `:bwr_r`, `:coolwarm`, `:coolwarm_r`, `:PiYG`, `:PiYG_r`, `:PRGn`, `:PRGn_r`, `:PuOr`, `:PuOr_r`, `:RdBu`, `:RdBu_r`, `:RdGy`, `:RdGy_r`, `:RdYlBu`, `:RdYlBu_r`, `:RdYlGn`, `:RdYlGn_r`, `:Spectral`, `:Spectral_r`, `:PuBu`, `:PuBu_r`, `:BuPu`, `:BuPu_r`, `:YlGn`, `:YlGn_r`, `:YlGnBu`, `:YlGnBu_r`, `:GnBu`, `:GnBu_r`, `:PuRd`, `:PuRd_r`, `:OrRd`, `:OrRd_r`, `:YlOrBr`, `:YlOrBr_r`, `:YlOrRd`, `:YlOrRd_r`, `:Reds`, `:Reds_r`, `:Greens`, `:Greens_r`, `:Blues`, `:Blues_r`, `:Purples`, `:Purples_r`, `:Oranges`, `:Oranges_r`, `:Greys`, `:Greys_r`, `:Pastel1`, `:Pastel1_r`, `:Pastel2`, `:Pastel2_r`, `:Set1`, `:Set1_r`, `:Set2`, `:Set2_r`, `:Set3`, `:Set3_r`, `:tab10`, `:tab10_r`, `:tab20`, `:tab20_r`, `:tab20b`, `:tab20b_r`, `:tab20c`, `:tab20c_r`.
- `z::Union{Nothing,Vector{<:Real}}=nothing`: A vector of values to use for colorizing the image. If `nothing`, the image will be colorized based on intensity.
- `z_range::Union{Nothing,Tuple{Real,Real}}=nothing`: The range of values to use for colorizing the image. If `nothing`, the range will be determined automatically from the values in `z`.
- `percentile_cutoff::Real=0.99`: The percentile cutoff for range scaling for intensity scaling.

# Returns
- `final_image::OffsetArray`: The combined image as a 2D array of RGB values.
"""
function combine_rois(rois::Vector{<:OffsetArray{Float32,2}},
    x_range::Tuple{Int,Int},
    y_range::Tuple{Int,Int},
    cmap::ColorScheme;
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing,
    percentile_cutoff::Real=0.99
)

    # Create a larger array to act as our final image
    final_image = OffsetArray(zeros(RGB{Float32},
            y_range[2] - y_range[1] + 1,
            x_range[2] - x_range[1] + 1),
        y_range[1]:y_range[2],
        x_range[1]:x_range[2])

    combine_rois!(final_image, rois, cmap; z, z_range)
    quantile_clamp!(final_image, percentile_cutoff)

    return final_image
end

function gen_blob!(blob::Blob, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol, zoom::Int=1)
    # Precompute constants
    inv_2σx2 = 1 / (2 * (zoom * σ_x)^2)
    inv_2σy2 = 1 / (2 * (zoom * σ_y)^2)
    x_zoom = x * zoom
    y_zoom = y * zoom

    # In-place computation of gaussian values
    @inbounds for i in CartesianIndices(blob.roi)
        y_i, x_i = Tuple(i)
        blob.roi[i] = exp(-((x_i - x_zoom)^2 * inv_2σx2 + (y_i - y_zoom)^2 * inv_2σy2))
    end

    # Normalize the gaussian
    if normalization == :integral
        blob.roi ./= sum(blob.roi)
    elseif normalization == :maximum
        blob.roi ./= maximum(blob.roi)
    end
    return nothing
end


# function gen_blob!(blob::Blob, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol, zoom::Int=1)

#     for i in CartesianIndices(blob.roi)
#         y_i, x_i = i[1], i[2]
#         blob.roi[i] = exp(-((x_i - x * zoom)^2 / (2 * (zoom * σ_x)^2) + (y_i - y * zoom)^2 / (2 * (zoom * σ_y)^2)))
#     end

#     # Normalize the gaussian
#     if normalization == :integral
#         blob.roi ./= sum(blob.roi)
#     elseif normalization == :maximum
#         blob.roi ./= maximum(blob.roi)
#     end
#     return nothing
# end


function add_blob!(im::AbstractArray{<:Real}, roi::OffsetArray{Float32,2})
    for idx::CartesianIndex{2} in CartesianIndices(roi)
        im[idx] += roi[idx]
    end
    return nothing
end

function add_blobs!(im::OffsetArray{Float32,2}, blobs::Vector{Blob})
    for blob in blobs
        add_blob!(im, blob.roi)
    end
    return nothing
end

function add_blobs!(im::OffsetArray{Float32,3}, blobs::Vector{Blob},
    cmap::ColorScheme, z_range::Tuple{Real,Real})

    for blob in blobs
        z_idx = Int(floor((blob.z - z_range[1]) / (z_range[2] - z_range[1]) * length(cmap.colors))) + 1
        # handle out of range z values by removal
        if z_idx < 1 || z_idx > length(cmap.colors)
            continue
        end
        
        add_blob!(view(im, :, :, z_idx), blob.roi)
    end
    return nothing
end




