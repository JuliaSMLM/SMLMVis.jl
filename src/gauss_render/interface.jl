

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
- `zoom::Int=1`: The zoom factor to apply to the image. Must be an even integer
- `percentile_cutoff::Real=0.99`: The percentile cutoff for intensity scaling.

# Returns
- `final_image, cmap, z_range`: The rendered image as a 2D array of RGB values, colormap and z_range used for rendering. 
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
    # Adjust the range for zoom
    if zoom > 1
        if zoom % 2 == 0
            x_range = Int.((x_range[1] - 0.5, x_range[2] + 0.5) .* zoom)
            y_range = Int.((y_range[1] - 0.5, y_range[2] + 0.5) .* zoom)
        else
            @error "Zoom must be an even number"
        end
    end

    # Make colormap
    cmap = create_colormap(z, colormap)

    # Determine whether we are creating a 2D or 3D image and initialize accordingly
    if isnothing(z) # 2D image
        gray_image = initialize_gray_image(x_range, y_range)  # Returns ImagePatch2D
    else # 3D image
        gray_image = initialize_gray_image(x_range, y_range, length(cmap.colors))  # Returns ImagePatch3D

        # Set z_range if not provided
        if isnothing(z_range)
            z_range = (minimum(z), maximum(z))
        end
    end

    n_blobs = length(x)

    # Calculate the size of the roi
    max_sigma = max(maximum(σ_x), maximum(σ_y))
    min_sigma = min(minimum(σ_x), minimum(σ_y))
    box_size = Int(ceil(2 * n_sigmas * max_sigma * zoom))


    FOUR_GB = 4 * 1024 * 1024 * 1024
    total_size = box_size * box_size * n_blobs * sizeof(Float64)
    num_sections = ceil(Int, total_size / FOUR_GB)
    section_size = floor(Int, n_blobs / num_sections)

    nthreads = Threads.nthreads()
    @info "Rendering $n_blobs blobs in $num_sections sections of size $section_size"
    @info "Using $box_size x $box_size rois and $nthreads threads"

    for n in 1:num_sections
        n_start = (n - 1) * section_size + 1
        n_end = min(n_start + section_size - 1, n_blobs)
        n_blobs_section = n_end - n_start + 1
        n_range = n_start:n_end

        blobs = generate_image_patches(n_blobs_section, x_range, y_range, x, y, z, n_range, box_size, zoom)

        render_image_patches!(blobs, x, y, σ_x, σ_y, normalization, zoom, n_range, n_start)

        combine_image_patches!(gray_image, blobs, z, cmap, z_range)
    end

    @info "Applying colormap"

    final_image = apply_colormap_to_image(gray_image, cmap, percentile_cutoff)

    @info "Done!"

    return final_image, cmap, z_range
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
    zoom::Int=1,
    percentile_cutoff::Real=0.99
)

    x_range = (1, smld.datasize[2])
    y_range = (1, smld.datasize[1])

    return render_blobs(
        x_range,
        y_range,
        smld.x,
        smld.y,
        smld.σ_x,
        smld.σ_y;
        normalization=normalization,
        n_sigmas=n_sigmas,
        colormap=colormap,
        zoom,
        percentile_cutoff
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
    zoom::Int=1,
    percentile_cutoff::Real=0.99
)

    x_range = (1, smld.datasize[2])
    y_range = (1, smld.datasize[1])

    return render_blobs(
        x_range,
        y_range,
        smld.x,
        smld.y,
        smld.σ_x,
        smld.σ_y;
        normalization=normalization,
        n_sigmas=n_sigmas,
        colormap=colormap,
        z=smld.z,
        z_range=z_range,
        zoom,
        percentile_cutoff
    )

end

