
# Modified Blob struct with manual offset fields
struct Blob{T<:Real} 
    roi :: Array{T, 2}
    offset_x :: Int
    offset_y :: Int
    z :: T
end

# Implement the gen_blob! function with manual offset handling
function gen_blob!(blob::Blob, x::Real, y::Real, σ_x::Real, σ_y::Real, normalization::Symbol, zoom::Int=1)
    zoom_σ_x = zoom * σ_x
    zoom_σ_y = zoom * σ_y
    inv_2σx2 = 1 / (2 * zoom_σ_x^2)
    inv_2σy2 = 1 / (2 * zoom_σ_y^2)
    x_zoom = (x - blob.offset_x) * zoom
    y_zoom = (y - blob.offset_y) * zoom

    @inbounds for i in CartesianIndices(blob.roi)
        y_i, x_i = Tuple(i)
        adjusted_x_i = x_i + blob.offset_x - 1
        adjusted_y_i = y_i + blob.offset_y - 1
        blob.roi[i] = exp(-((adjusted_x_i - x_zoom)^2 * inv_2σx2 + (adjusted_y_i - y_zoom)^2 * inv_2σy2))
    end

    if normalization == :integral
        blob.roi .= blob.roi ./ sum(blob.roi)
    elseif normalization == :maximum
        blob.roi .= blob.roi ./ maximum(blob.roi)
    end
end

# Parameters for blob generation
n_blobs = 100000
blob_size = (25, 25)
initial_z = 0.0  # Example initial value for z
offset_x, offset_y = 1, 1  # Example offset values
blobs = [Blob(zeros(Float64, blob_size), offset_x, offset_y, initial_z) for _ in 1:n_blobs]

# Sample parameters for gen_blob!
x, y, σ_x, σ_y, normalization, zoom = 12.5, 12.5, 3.0, 3.0, :integral, 1

# Process the blobs in parallel
@time Threads.@threads for i in 1:n_blobs
    gen_blob!(blobs[i], x, y, σ_x, σ_y, normalization, zoom)
end
