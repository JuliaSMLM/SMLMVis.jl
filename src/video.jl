using FFMPEG

function save_to_mp4(arr::Array{Float64, 3}, filename::AbstractString; fps::Int=30, crf::Int=23)
    # Get dimensions of array
    nframes, height, width = size(arr)

    # Create video writer object with specified frame rate and compression level
    writer = FFMPEG.VideoWriter(filename, height, width, fps=fps, crf=crf)

    # Loop through each frame and write to video
    for i in 1:nframes
        frame = arr[i,:,:]
        write(writer, frame)
    end

    # Close video writer
    close(writer)
end

