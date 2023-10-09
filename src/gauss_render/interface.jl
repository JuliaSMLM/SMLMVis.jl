

"""
render_blobs(
    x_range::Tuple{Int,Int},
    y_range::Tuple{Int,Int},
    x::Vector{<:Real},
    y::Vector{<:Real},
    σ_x::Vector{<:Real},
    σ_y::Vector{<:Real};
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Union{Nothing,Symbol}=nothing,
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing,
    zoom::Int=1,
    percentile_cutoff::Real=0.99
    )

Render a stack of 2D Gaussian blobs as a single image.

# Arguments
- `x_range::Tuple{Int,Int}`: The range of valid x-coordinates for the final image.
- `y_range::Tuple{Int,Int}`: The range of valid y-coordinates for the final image.
- `x::Vector{<:Real}`: A vector of x-coordinates for the centers of the Gaussian blobs.
- `y::Vector{<:Real}`: A vector of y-coordinates for the centers of the Gaussian blobs.
- `σ_x::Vector{<:Real}`: A vector of standard deviations for the Gaussian blobs in the x-direction.
- `σ_y::Vector{<:Real}`: A vector of standard deviations for the Gaussian blobs in the y-direction.
- `normalization::Symbol=:integral`: The type of normalization to apply to the Gaussian blobs. Valid options are `:integral` (normalize the blobs so that their integrals are 1) and `:maximum` (normalize the blobs so that their maximum values are 1).
- `n_sigmas::Real=3`: The number of standard deviations to use for calculating the size of the region of interest (ROI) around each Gaussian blob.
- `colormap::Union{Nothing,Symbol}=nothing`: The name of the colormap to use for colorizing the image. Valid options are `:viridis`, `:plasma`, `:inferno`, `:magma`, `:cividis`, `:rainbow_bgyr_35_85_c72_n256`, `:hot`, `:cool`, `:spring`, `:summer`, `:autumn`, `:winter`, `:bone`, `:copper`, `:pink`, `:gray`, `:binary`, `:gist_earth`, `:terrain`, `:ocean`, `:jet`, `:nipy_spectral`, `:gist_ncar`, `:gist_rainbow`, `:hsv`, `:flag`, `:prism`, `:flag_r`, `:prism_r`, `:rainbow`, `:rainbow_r`, `:seismic`, `:seismic_r`, `:brg`, `:brg_r`, `:bwr`, `:bwr_r`, `:coolwarm`, `:coolwarm_r`, `:PiYG`, `:PiYG_r`, `:PRGn`, `:PRGn_r`, `:PuOr`, `:PuOr_r`, `:RdBu`, `:RdBu_r`, `:RdGy`, `:RdGy_r`, `:RdYlBu`, `:RdYlBu_r`, `:RdYlGn`, `:RdYlGn_r`, `:Spectral`, `:Spectral_r`, `:PuBu`, `:PuBu_r`, `:BuPu`, `:BuPu_r`, `:YlGn`, `:YlGn_r`, `:YlGnBu`, `:YlGnBu_r`, `:GnBu`, `:GnBu_r`, `:PuRd`, `:PuRd_r`, `:OrRd`, `:OrRd_r`, `:YlOrBr`, `:YlOrBr_r`, `:YlOrRd`, `:YlOrRd_r`, `:Reds`, `:Reds_r`, `:Greens`, `:Greens_r`, `:Blues`, `:Blues_r`, `:Purples`, `:Purples_r`, `:Oranges`, `:Oranges_r`, `:Greys`, `:Greys_r`, `:Pastel1`, `:Pastel1_r`, `:Pastel2`, `:Pastel2_r`, `:Set1`, `:Set1_r`, `:Set2`, `:Set2_r`, `:Set3`, `:Set3_r`, `:tab10`, `:tab10_r`, `:tab20`, `:tab20_r`, `:tab20b`, `:tab20b_r`, `:tab20c`, `:tab20c_r`.
- `z::Union{Nothing,Vector{<:Real}}=nothing`: A vector of values to use for colorizing the image. If `nothing`, the image will be colorized based on intensity.
- `z_range::Union{Nothing,Tuple{Real,Real}}=nothing`: The range of values to use for colorizing the image. If `nothing`, the range will be determined automatically from the values in `z`.
- `zoom::Int=1`: The zoom factor to apply to the image.
- `percentile_cutoff::Real=0.99`: The percentile cutoff for intensity scaling.

# Returns
- `final_image::OffsetArray`: The rendered image as a 2D array of RGB values.
"""
function render_blobs(
    x_range::Tuple{Int,Int},
    y_range::Tuple{Int,Int},
    x::Vector{<:Real},
    y::Vector{<:Real},
    σ_x::Vector{<:Real},
    σ_y::Vector{<:Real};
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Union{Nothing,Symbol}=nothing,
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing,
    zoom::Int=1,
    percentile_cutoff::Real=0.99
)

    x_range = x_range .*zoom
    y_range = y_range .* zoom

    # Create a larger array to act as our final image
    # final_image = OffsetArray(zeros(RGB{Float32},
    #         y_range[2] - y_range[1] + 1,
    #         x_range[2] - x_range[1] + 1),
    #     y_range[1]:y_range[2],
    #     x_range[1]:x_range[2])

    final_image = RGBArray{Float32}((
        y_range[2] - y_range[1] + 1,
        x_range[2] - x_range[1] + 1),
    (y_range[1]:y_range[2],
    x_range[1]:x_range[2]))

    if isnothing(z) && isnothing(colormap)
        cmap = ColorSchemes.hot
    elseif !isnothing(z) && isnothing(colormap)
        cmap = ColorSchemes.rainbow_bgyr_35_85_c72_n256
    else
        cmap = getfield(ColorSchemes, colormap)
    end

    n_blobs = length(x)

    # calculate the size of the roi
    max_sigma = max(maximum(σ_x), maximum(σ_y))
    box_size = Int(ceil(2 * n_sigmas * max_sigma * zoom))

    println(box_size)

    EIGHT_GB = 8 * 1024 * 1024 * 1024

    # Total memory size for the 3D array
    total_size = box_size * box_size * n_blobs * sizeof(Float32)

    # Number of sections required to fit the 3D array into 8 GB sections
    num_sections = ceil(Int, total_size / EIGHT_GB)

    # Size of each section along the third dimension
    section_size = floor(Int, n_blobs / num_sections)

    for n in 1:num_sections

        # calculate range of roi indexes to calculate

        n_start = (n - 1) * section_size + 1
        n_end = min(n_start + section_size - 1, n_blobs)
        n_blobs_section = n_end - n_start + 1
        n_range = n_start:n_end

        # calculate the range of the rois in final image
        range_tuples = calc_range.(x[n_range], y[n_range], box_size, Ref(x_range), Ref(y_range), zoom)

        # generate an empty stack of OffsetArrays
        rois = Vector{OffsetArray{Float32,2}}(undef, n_blobs_section)
        for i in 1:n_blobs_section
            rois[i] = OffsetArray(zeros(Float32, box_size, box_size),
                range_tuples[i][1],
                range_tuples[i][2]
            )
        end

        @info "Rendering Blobs"
        # render the blobs
        for i in n_range
            blob!(rois[i - n_start + 1], x[i], y[i], σ_x[i], σ_y[i], normalization, zoom)
        end

        # combine the rois into a single image
        @info "Combining rois"
        combine_rois!(final_image, rois, cmap;
            z = z[n_range], z_range)

    end

    quantile_clamp!(final_image, percentile_cutoff)

    final_image = RGB.(final_image.r,final_image.g, final_image.b)
    return final_image, (cmap, z_range)
end

"""
render_blobs(smld::SMLMData.SMLD2D; 
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Symbol=:hot
    )

"""
function render_blobs(smld::SMLMData.SMLD2D;
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Symbol=:hot,
    zoom::Int=1
)

    return render_blobs(
        (1, smld.datasize[2]),
        (1, smld.datasize[1]),
        smld.x,
        smld.y,
        smld.σ_x,
        smld.σ_y;
        normalization=normalization,
        n_sigmas=n_sigmas,
        colormap=colormap,
        zoom
    )

end

"""
render_blobs(smld::SMLMData.SMLD3D; 
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Symbol=:rainbow_bgyr_35_85_c72_n256,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
    )

"""
function render_blobs(smld::SMLMData.SMLD3D;
    normalization::Symbol=:integral,
    n_sigmas::Real=3,
    colormap::Symbol=:rainbow_bgyr_35_85_c72_n256,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing,
    zoom::Int=1
)

    return render_blobs(
        (1, smld.datasize[2]),
        (1, smld.datasize[1]),
        smld.x,
        smld.y,
        smld.σ_x,
        smld.σ_y;
        normalization=normalization,
        n_sigmas=n_sigmas,
        colormap=colormap,
        z=smld.z,
        z_range=(minimum(smld.z), maximum(smld.z)),
        zoom
    )

end

