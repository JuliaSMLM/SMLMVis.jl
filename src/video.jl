
function save_to_mp4(filename::AbstractString, arr::Array{<:Real,3}; fps::Int=30, crf::Int=23)


    # Convert array to array of arrays of type N0f8
    imgstack = Array{Array{Gray{N0f8},2}}(undef, size(arr, 3))
    for i in 1:size(arr, 3)
        imgstack[i] = Array{Gray{N0f8},2}(undef, size(arr)[1], size(arr)[2])
        minval = minimum(arr)
        maxval = maximum(arr)
        for j in 1:size(arr, 1)
            for k in 1:size(arr, 2)
                imgstack[i][j, k] = Gray{N0f8}((arr[j, k, i] - minval) / (maxval - minval))
            end
        end
    end

    @info "Saving video to $filename"
    encoder_options = (crf=crf, preset="medium")
    VideoIO.save(filename, imgstack, framerate=fps, encoder_options=encoder_options)

    return nothing
end

