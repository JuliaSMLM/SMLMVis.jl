
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
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
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
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
    )

    n_blobs = length(x)

    # calculate the size of the roi
    max_sigma = max(maximum(σ_x), maximum(σ_y))
    box_size = Int(ceil(2 * n_sigmas * max_sigma))

    # calculate the range or the rois
    range_tuples = calc_range.(x, y, box_size, Ref(x_range), Ref(y_range))

    # generate an empty stack of OffsetArrays
    rois = Vector{OffsetArray{Float32,2}}(undef, n_blobs)
    for i in 1:n_blobs
        rois[i] = OffsetArray(zeros(Float32, box_size, box_size), 
        range_tuples[i][1],
        range_tuples[i][2] 
        )
    end

    # render the blobs
    for i in 1:n_blobs
        blob!(rois[i], x[i], y[i], σ_x[i], σ_y[i], normalization)
    end

    # combine the rois into a single image
    final_image = combine_rois(rois, x_range, y_range; z, z_range, colormap)

    return final_image
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
    colormap::Symbol=:hot
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
        colormap=colormap
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
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
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
        z_range=(minimum(smld.z), maximum(smld.z))
    )

end

