
"""
    isMIC(filename::AbstractString)

Check if an HDF5 file has the expected group structure for a MIC file.

# Arguments
- `filename::AbstractString`: The name of the HDF5 file to check.

# Returns
- `out::Bool`: `true` if the file has the expected group structure, `false` otherwise.
"""
function isMIC(filename::AbstractString)
    # Open HDF5 file
    file = h5open(filename, "r")

    # Check if file has expected group structure
    if haskey(file, "Channel01/Zposition001")
        out = true
    else
        out = false
    end

    close(file)
    return out
end

"""
    count_datasets(filename::AbstractString; groupname::AbstractString="Channel01/Zposition001")

Count the number of datasets in an HDF5 file.

# Arguments
- `filename::AbstractString`: The name of the HDF5 file to count datasets in.
- `groupname::AbstractString`: The name of the group to count datasets in. Default is "Channel01/Zposition001".

# Returns
- `n_datasets::Int`: The number of datasets in the specified group.
"""
function count_datasets(filename::AbstractString; groupname::AbstractString="Channel01/Zposition001")
    file = h5open(filename, "r")

    # Get list of object names in group
    object_names = keys(file[groupname])
    n_datasets = length(object_names)
    close(file)
    return n_datasets
end

"""
    readMIC(filename::AbstractString;
        groupname::AbstractString="Channel01/Zposition001",
        datasetnum::Int=1)

Read data from a MIC HDF5 file.

# Arguments
- `filename::AbstractString`: The name of the HDF5 file to read data from.
- `groupname::AbstractString`: The name of the group to read data from. Default is "Channel01/Zposition001".
- `datasetnum::Int`: The number of the dataset to read. Default is 1.

# Returns
- `data::Array`: The data read from the specified dataset.
"""
function readMIC(filename::AbstractString;
    groupname::AbstractString="Channel01/Zposition001",
    datasetnum::Int=1)


    if ~isMIC(filename)
        @error "File $filename is not a MIC file."
    end

    # Count number of datasets in group
    ndatasets = count_datasets(filename)
    if datasetnum > ndatasets
        @error "Dataset number $datasetnum is greater than the number of datasets in the file ($ndatasets)."
    end


    datagroupname = "Data" * lpad(datasetnum, 4, "0")
    # check if datagroupname is a group or dataset

    file = h5open(filename, "r")
    g = file[groupname]
    if isa(g[datagroupname], HDF5.Dataset) # TIRF data
        @info "This is a TIRF Data file."
        datasetname = groupname * "/" * datagroupname
    else # SeqSR data
        @info "This is a SeqSR Data file."
        datasetname = groupname * "/" * datagroupname * "/" * datagroupname
    end
    
    close(file)
    
    # Read data from dataset
    data = h5read(filename, datasetname)

    return data
end

"""
    mic2mp4(filename::AbstractString;
        savefilename::Union{Nothing,AbstractString}=nothing,
        groupname::AbstractString="Channel01/Zposition001",
        datasetnum::Int=1,
        framenormalize::Bool=false,
        fps::Int=30,
        crf::Int=23)

Convert a MIC HDF5 file to an MP4 video.

# Arguments
- `filename::AbstractString`: The name of the HDF5 file to convert.
- `savefilename::Union{Nothing,AbstractString}`: The name of the output MP4 file. If `nothing`, the output file is named after the input file. Default is `nothing`.
- `groupname::AbstractString`: The name of the group to convert. Default is "Channel01/Zposition001".
- `datasetnum::Int`: The number of the dataset to convert. Default is 1.
- `framenormalize::Bool`: Whether to normalize each frame of the dataset individually. Default is `false`.
- `fps::Int`: The frames per second of the output video. Default is 30.
- `crf::Int`: The constant rate factor of the output video. Default is 23.

# Returns
- `nothing`

This function converts a MIC HDF5 file to an MP4 video using the specified group, dataset number, frames per second, and constant rate factor. The output video is saved to the specified output file, or named after the input file if no output file is specified. If `framenormalize` is `true`, each frame of the dataset is normalized individually. The function returns `nothing`.
"""
function mic2mp4(filename::AbstractString;
    savefilename::Union{Nothing,AbstractString}=nothing,
    groupname::AbstractString="Channel01/Zposition001",
    datasetnum::Int=1,
    framenormalize::Bool=false,
    fps::Int=30,
    crf::Int=23)

    # Read data from MIC file
    @info "Reading data from $filename"
    data = Float32.(readMIC(filename, groupname=groupname, datasetnum=datasetnum))

    # Save data to mp4 file
    if isnothing(savefilename)
        basefilename = split(filename, ".")[1]
        savefilename = basefilename * ".mp4"
    end

    @info "normalizing data"
    if framenormalize
        for i in 1:size(data)[3]
            normalize!(view(data, :, :, i))
        end
    else
        normalize!(data)
    end

    SMLMVis.save_to_mp4(savefilename, data, fps=fps, crf=crf)

    return nothing
end

"""
    readMIC(filename::AbstractString;
        groupname::AbstractString="Channel01/Zposition001",
        datasetnum::Int=1)

Read data from a MIC HDF5 file.

# Arguments
- `filename::AbstractString`: The name of the HDF5 file to read data from.
- `groupname::AbstractString`: The name of the group to read data from. Default is "Channel01/Zposition001".
- `datasetnum::Int`: The number of the dataset to read. Default is 1.

# Returns
- `data::Array`: The data read from the specified dataset.
"""
function normalize!(arr::AbstractArray{<:Real};
    minval::Union{Real,Nothing}=nothing,
    maxval::Union{Real,Nothing}=nothing)

    # Get min and max values of array
    if isnothing(minval)
        minval = minimum(arr)
    end
    if isnothing(maxval)
        maxval = maximum(arr)
    end

    # Normalize array
    arr .= (arr .- minval) ./ (maxval - minval)
    arr .= clamp.(arr, 0, 1)

    return nothing
end
