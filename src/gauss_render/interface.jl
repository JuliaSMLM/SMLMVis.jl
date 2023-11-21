

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
- `final_image, (cmap, z_range)`: The rendered image as a 2D array of RGB values, colormap and z_range used for rendering. 
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

    # pixels mean center of pixel, so 1 to 256 means 0.5 to 256.5

    if zoom > 1
        if zoom % 2 == 0
            x_range = Int.((x_range[1]-0.5, x_range[2]+.5) .* zoom)
            y_range = Int.((y_range[1]-0.5, y_range[2]+.5) .* zoom)
        else
            @error "Zoom must be an even number"
        end
    end


    # Make colormap
    if isnothing(z) && isnothing(colormap)
        cmap = ColorSchemes.hot
    elseif !isnothing(z) && isnothing(colormap)
        cmap = ColorSchemes.rainbow_bgyr_35_85_c72_n256
    else
        cmap = getfield(ColorSchemes, colormap)
    end

    # Create an OffsetArray array to act as our final image
    if isnothing(z) # 2D image
        final_image = OffsetArray(zeros(Float32,
                y_range[2] - y_range[1] + 1,
                x_range[2] - x_range[1] + 1),
            y_range[1]:y_range[2],
            x_range[1]:x_range[2])
    else # 3D image of length of colormap
        final_image = OffsetArray(zeros(Float32,
                y_range[2] - y_range[1] + 1,
                x_range[2] - x_range[1] + 1,
                length(cmap.colors)),
            y_range[1]:y_range[2],
            x_range[1]:x_range[2],
            1:length(cmap.colors))
    end

    if ~isnothing(z)
        if isnothing(z_range)
            z_range = (minimum(z), maximum(z))
        end
    end

    @info "x_range: $x_range, y_range: $y_range, z_range: $z_range"

    n_blobs = length(x)

    # calculate the size of the roi
    max_sigma = max(maximum(σ_x), maximum(σ_y))
    min_sigma = min(minimum(σ_x), minimum(σ_y))
    box_size = Int(ceil(2 * n_sigmas * max_sigma * zoom))

    @info "Max sigma: $max_sigma, Min sigma: $min_sigma, Box size: $box_size"
    println(box_size)

    FOUR_GB = 4 * 1024 * 1024 * 1024

    # Total memory size for the 3D array
    total_size = box_size * box_size * n_blobs * sizeof(Float32)

    # Number of sections required to fit the 3D array into 8 GB sections
    num_sections = ceil(Int, total_size / FOUR_GB)

    # Size of each section along the third dimension
    section_size = floor(Int, n_blobs / num_sections)

    nthreads = Threads.nthreads()
    @info "Rendering $n_blobs blobs in $num_sections sections of size $section_size"
    @info "using $box_size x $box_size rois and $nthreads() threads"

    for n in 1:num_sections

        # calculate range of roi indexes to calculate

        n_start = (n - 1) * section_size + 1
        n_end = min(n_start + section_size - 1, n_blobs)
        n_blobs_section = n_end - n_start + 1
        n_range = n_start:n_end

        # calculate the range of the rois in final image
        range_tuples = calc_range.(x[n_range], y[n_range], box_size, Ref(x_range), Ref(y_range), zoom)

        # generate an empty stack of OffsetArrays
        blobs = Vector{Blob}(undef, n_blobs_section)
        for i in 1:n_blobs_section
            blobs[i] = Blob(OffsetArray(zeros(Float32, box_size, box_size),
                    range_tuples[i][1],
                    range_tuples[i][2]
                ),
                isnothing(z) ? 0.0 : z[n_range[i]])
        end

        @info "Rendering Blobs"
        @time begin
            # render the blobs in parallel
            Threads.@threads for i in n_range
                gen_blob!(blobs[i-n_start+1], x[i], y[i], σ_x[i], σ_y[i], normalization, zoom)
            end
        end

        # combine the rois into a single image
        @info "Combining rois"

        if isnothing(z)
            add_blobs!(final_image, blobs)
        else
            add_blobs!(final_image, blobs, cmap, z_range)
        end

    end


    # apply the colormap
    if isnothing(z)
        quantile_clamp!(final_image, percentile_cutoff)
        final_image = get(cmap, final_image)
    else
        display(typeof(final_image))

        r = [cmap[i].r .* final_image.parent[:, :, i] for i in 1:length(cmap)]
        g = [cmap[i].g .* final_image.parent[:, :, i] for i in 1:length(cmap)]
        b = [cmap[i].b .* final_image.parent[:, :, i] for i in 1:length(cmap)]

        r = cat(r..., dims=3)
        g = cat(g..., dims=3)
        b = cat(b..., dims=3)

        display(length(r))
        display(typeof(r))
        imshow(RGB.(r, g, b))

        r = sum([cmap[i].r .* final_image.parent[:, :, i] for i in 1:length(cmap)])
        g = sum([cmap[i].g .* final_image.parent[:, :, i] for i in 1:length(cmap)])
        b = sum([cmap[i].b .* final_image.parent[:, :, i] for i in 1:length(cmap)])



        # find quantile cutoff over all colors

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

        @info "Max val: $max_val"
        r ./= max_val
        g ./= max_val
        b ./= max_val

        clamp!(r, 0, 1)
        clamp!(g, 0, 1)
        clamp!(b, 0, 1)

        final_image = RGB{Float32}.(r, g, b)

    end


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
        zoom
    )

end

