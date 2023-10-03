
"""
blob!(roi::OffsetArray, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol)

Populate the `roi` array with a 2D Gaussian blob centered at `(x, y)` with standard deviations `σ_x` and `σ_y`.

# Arguments
- `roi::OffsetArray{Float32,2}`: The 2D array to populate with the Gaussian blob.
- `x::Real`: The x-coordinate of the center of the Gaussian blob.
- `y::Real`: The y-coordinate of the center of the Gaussian blob.
- `σ_x::Real`: The standard deviation of the Gaussian blob in the x-direction.
- `σ_y::Real`: The standard deviation of the Gaussian blob in the y-direction.
- `normalization::Symbol`: The type of normalization to apply to the Gaussian blob. Valid options are `:integral` (normalize the blob so that its integral is 1) and `:maximum` (normalize the blob so that its maximum value is 1).
- `zoom::Int`: The zoom factor to apply to the Gaussian blob.

# Returns
`nothing`
"""
function blob!(roi::OffsetArray{Float32,2}, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol, zoom::Int=1)
    
    for i in CartesianIndices(roi)
        y_i, x_i = i[1], i[2]
        roi[i] = exp(-((x_i - x * zoom)^2 / (2 * (zoom * σ_x)^2) + (y_i - y * zoom)^2 / (2 * (zoom * σ_y)^2)))
    end

    # Normalize the gaussian
    if normalization == :integral
        roi = roi ./ sum(roi)
    elseif normalization == :maximum
        roi = roi ./ maximum(roi)
    end
    return nothing
end


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
    x_range_roi = x_start:(x_start + box_size - 1)
    y_range_roi = y_start:(y_start + box_size - 1)

    return y_range_roi, x_range_roi
end

function update_final_image!(final_image::OffsetArray{RGB{Float32}, 2}, rois::Vector{OffsetArray{Float32, 2}})
    color = RGB{Float32}(1, 1, 1)
    for roi in rois
        for idx::CartesianIndex{2} in CartesianIndices(roi)
            final_image[idx] += roi[idx] * color
        end
    end
end

function update_final_image_with_cmap!(
    final_image::OffsetArray{RGB{Float32}, 2}, 
    rois::Vector{OffsetArray{Float32, 2}},
    cmap::ColorScheme,
    z::Vector{<:Real},
    z_min::Real,
    z_max::Real
)

for i in 1:length(rois)
    # Calculate color based on z[i]
    color = get(cmap, (z[i] - z_min) / (z_max - z_min))
    
    # Update final_image based on rois[i]
    for idx::CartesianIndex{2} in CartesianIndices(rois[i])
        final_image[idx] += rois[i][idx] * color
    end
end
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
    y_range[2]-y_range[1] + 1, 
    x_range[2]-x_range[1] + 1), 
    y_range[1]:y_range[2], 
    x_range[1]:x_range[2])

    if ~isnothing(z) # color is based on z
        @info "Coloring based on z"
        if ~isnothing(z_range)
            z_min, z_max = z_range
        else
            z_min, z_max = minimum(z), maximum(z)
        end
        update_final_image_with_cmap!(final_image, rois, cmap, z, z_min, z_max)
        r = red.(final_image)
        g = green.(final_image)
        b = blue.(final_image)
        max_val = max(quantile(r[r.>0],percentile_cutoff), 
        maximum(quantile(g[g.>0],percentile_cutoff)), 
        maximum(quantile(b[b.>0],percentile_cutoff)))
        r /= max_val
        g /= max_val
        b /= max_val
        clamp!(r, 0, 1)
        clamp!(g, 0, 1)
        clamp!(b, 0, 1)
        final_image = RGB.(r,g,b)
    else
        @info "Coloring based on intensity"
        update_final_image!(final_image, rois)
        # Normalize the image using percentile cutoff
        r = red.(final_image)
        max_val = quantile(r[r.>0], percentile_cutoff)        
        final_image /= max_val
        final_image = get(cmap, red.(final_image))
    end

    return final_image
end





