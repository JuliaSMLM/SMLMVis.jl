
"""
    save_to_mp4(filename::AbstractString, arr::Array{<:Real,3};
        fps::Int=30, crf::Int=23)

Save an array of 3D images to an MP4 video.

# Arguments
- `filename::AbstractString`: The name of the output MP4 file.
- `arr::Array{<:Real,3}`: The array of 3D images to save.
- `fps::Int`: The frames per second of the output video. Default is 30.
- `crf::Int`: The constant rate factor of the output video. Default is 23.

# Returns
- `nothing`

This function saves an array of 3D images to an MP4 video using the specified frames per second and constant rate factor. The output video is saved to the specified output file. The function returns `nothing`.
"""
function save_to_mp4(filename::AbstractString, arr::Array{<:Real,3}; fps::Int=30, crf::Int=23)

    @info "Converting array to imgstack"
    imgstack = arr2imgstack(arr)
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

# Returns
- `imgstack::Array{Array{Gray{N0f8},2}}`

This function converts an 3D array to an array of matrices of type `N0f8`.
"""
function arr2imgstack(arr::Array{<:Real,3})
    # Pre-allocate output array
    imgstack = Array{Array{Gray{N0f8},2}}(undef, size(arr, 3))

    # Pre-allocate sub-arrays
    height, width = size(arr, 1), size(arr, 2)
    for i in 1:size(imgstack, 1)
        imgstack[i] = Array{Gray{N0f8},2}(undef, height, width)
    end

    minval = minimum(arr)
    maxval = maximum(arr)
    
    # Normalize and convert input array to output array
    for i in 1:size(arr, 3)
        imgstack[i] .= Gray{N0f8}.((arr[:,:,i] .- minval) ./ (maxval - minval))
    end
    
    return imgstack
end