
function blob!(roi::OffsetArray, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol)
    
    for i in CartesianIndices(roi)
        y_i, x_i = i[1], i[2]
        roi[i] = exp(-((x_i - x)^2 / (2 * σ_x^2) + (y_i - y)^2 / (2 * σ_y^2)))
    end

    # Normalize the gaussian
    if normalization == :integral
        roi = roi ./ sum(roi)
    elseif normalization == :maximum
        roi = roi ./ maximum(roi)
    end
    return nothing
end

# apply a colormap to an image

function apply_color!(roi::Array{<:Real}, color::RGB{Float32})
    for i in CartesianIndices(roi)
        roi[i] .= color*roi[i]
    end
    return nothing
end


# function that calculates the range roi from maximum sigma and number of sigmas
function calc_range(x::Real, y::Real, box_size::Int,
    x_range::Tuple{Int,Int}, y_range::Tuple{Int,Int})
    
    # Calculate the starting x-coordinate of the box
    x_start = Int(floor(max(x - box_size / 2, x_range[1])))
    x_start = Int(floor(min(x_start, x_range[2] - box_size)))

    # Calculate the starting y-coordinate of the box
    y_start = Int(floor(max(y - box_size / 2, y_range[1])))
    y_start = Int(floor(min(y_start, y_range[2] - box_size)))

    # Create ROI ranges
    x_range_roi = x_start:(x_start + box_size - 1)
    y_range_roi = y_start:(y_start + box_size - 1)

    return y_range_roi, x_range_roi
end


function combine_rois(rois::Vector{<:OffsetArray}, 
    x_range::Tuple{Int,Int}, 
    y_range::Tuple{Int,Int};
    colormap::Union{Nothing,Symbol}=nothing,
    z::Union{Nothing,Vector{<:Real}}=nothing,
    z_range::Union{Nothing,Tuple{Real,Real}}=nothing
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
        if isnothing(colormap)
            cmap = ColorSchemes.rainbow_bgyr_35_85_c72_n256
        else
            cmap = getfield(ColorSchemes, colormap)
        end
        for i in 1:length(rois)
            color = get(cmap, (z[i] - z_min) / (z_max - z_min))
            for idx in CartesianIndices(rois[i])
                final_image[idx] += rois[i][idx]*color
            end
        end
    else
        @info "Coloring based on intensity"
        if isnothing(colormap)
            cmap = ColorSchemes.hot
        else
            cmap = getfield(ColorSchemes, colormap)
        end
        color = RGB{Float32}(1,1,1)
        for roi in rois
            for idx in CartesianIndices(roi)
                final_image[idx] += roi[idx]*color
            end
        end    
    end

    max_val = max(maximum(red.(final_image)), maximum(green.(final_image)), maximum(blue.(final_image)))
    final_image /= max_val

    if isnothing(z)
        final_image = get(cmap, red.(final_image))
    end

    return final_image
end





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
    # calculate the corners of the roi
    range_tuples = calc_range.(x, y, box_size, Ref(x_range), Ref(y_range))

    # generate a stack of OffsetArrays
    rois = Vector{OffsetArray{Float32,2}}(undef, n_blobs)
    for i in 1:n_blobs
        rois[i] = OffsetArray(zeros(Float32, box_size, box_size), 
        range_tuples[i][1],
        range_tuples[i][2] 
        )
    end

    for i in 1:n_blobs
        blob!(rois[i], x[i], y[i], σ_x[i], σ_y[i], normalization)
    end

    # find the right color for each blob based on z and z_range and colormap
    
    final_image = combine_rois(rois, x_range, y_range; z, z_range, colormap)

    return final_image
end

