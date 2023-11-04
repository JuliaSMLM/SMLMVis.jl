
"""
    save_to_mp4(filename::AbstractString, arr::Array{<:Real,3};
        fps::Int=30, crf::Int=23)

Save an array of 3D images to an MP4 video.

# Arguments
- `filename::AbstractString`: The name of the output MP4 file.
- `arr::Array{<:Real,3}`: The array of 3D images to save.
- `fps::Int`: The frames per second of the output video. Default is 30.
- `crf::Int`: The constant rate factor of the output video. Default is 23.
- `zoom::Int`: The zoom factor to apply to each frame. Default is 1.

# Returns
- `nothing`

This function saves an array of 3D images to an MP4 video using the specified frames per second and constant rate factor. The output video is saved to the specified output file. The function returns `nothing`.
"""
function save_to_mp4(filename::AbstractString, arr::Array{<:Real,3}; fps::Int=30, crf::Int=23, zoom::Int=1)
    @info "Converting array to imgstack"
    imgstack = arr2imgstack(arr; zoom=zoom)
    @info "Saving video to $filename"
    encoder_options = (crf=crf, preset="medium")
    VideoIO.save(filename, imgstack, framerate=fps, encoder_options=encoder_options)
    return nothing
end

"""
    arr2imgstack(arr::Array{<:Real,3})

Convert an array of 3D images to an array of arrays of type `N0f8`.

# Arguments
- `arr::Array{<:Real,3}`: The array of 3D images to convert.
- `zoom::Int`: The zoom factor to apply to each frame. Default is 1.


# Returns
- `imgstack::Array{Array{Gray{N0f8},2}}`

This function converts an 3D array to an array of matrices of type `N0f8`.
"""
function arr2imgstack(arr::Array{<:Real,3}; zoom::Int=1)
    
    # Pre-allocate output array
    imgstack = Array{Array{Gray{N0f8},2}}(undef, size(arr, 3))

    # Pre-allocate sub-arrays
    height, width = size(arr, 1), size(arr, 2)
    for i in 1:size(imgstack, 1)
        imgstack[i] = Array{Gray{N0f8},2}(undef, zoom*height, zoom*width)
    end

    minval = minimum(arr)
    maxval = maximum(arr)
    
    # Normalize and convert input array to output array
    for i in 1:size(arr, 3)
        frame = block_resample(arr[:,:,i], zoom)
        imgstack[i] .= Gray{N0f8}.((frame .- minval) ./ (maxval - minval))
    end
    
    return imgstack
end

"""
    block_resample(array::Array, zoom::Int)

Resample an array by repeating each index a specified number of times. This function effectively increases the size of the array by a factor of `zoom` in each dimension.

# Arguments
- `array::Array`: The array to be resampled.
- `zoom::Int`: The factor by which to increase the size of the array.

# Returns
- `Array`: The resampled array.
"""
function block_resample(array::Array, zoom::Int)
    # Create an indexing array for each dimension that repeats each index zoom_factor times
    rows = repeat(1:size(array, 1), inner = zoom)
    cols = repeat(1:size(array, 2), inner = zoom)
    
    # Use indexing to create the zoomed array
    zoomed_array = array[rows, cols]
    
    return zoomed_array
end

