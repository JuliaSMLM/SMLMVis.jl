

# read an h5 file and save the data to an mp4 file. 

function is_MIC(filename::AbstractString)
    # Open HDF5 file
    file = h5open(filename, "r")

    # Show group structure of file
    show_tree(file)

    # Check if file has expected group structure
    if haskey(file, "Channel01") && haskey(file, "Zposition001")
        println("File $filename has expected group structure.")
        out = true
    else
        println("File $filename does not have expected group structure.")
        out = false
    end

    # Close HDF5 file
    close(file)
    return out
end

function count_datasets(filename::AbstractString; groupname::AbstractString="Channel01/Zposition001")
    file = h5open(fn, "r")
    HDF5.show_tree(file)
    # data = h5read(file)

    # Get list of object names in group
    object_names = names(file[groupname])

    # Get list of object names in group
    object_names = keys(file[groupname])
    n_datasets = length(object_names)
    close(file)
    return n_datasets
end

function readMIC(filename::AbstractString; groupname::AbstractString="Channel01/Zposition001"; datasetnum::Int=1)
    # Open HDF5 file

    if ~is_MIC(filename)
        @error "File $filename is not a MIC file."
    end

    file = h5open(filename, "r")

    ndatasets = count_datasets(filename)

    if datasetnum > ndatasets
        @error "Dataset number $datasetnum is greater than the number of datasets in the file ($ndatasets)."
    end

    # Make dataset name from dataset number
    datagroupname = "Data" * lpad(datasetnum, 4, "0")
    datasetname = datagroupname * "/" * datagroupname

    # Read data from dataset
    data = h5read(file, datasetname)

    # Close HDF5 file
    close(file)
    return data
end

function mp4(filename::AbstractString; 
    savefilename::Union{nothing,AbstractString}=nothing,
    groupname::AbstractString="Channel01/Zposition001"; 
    datasetnum::Int=1, 
    fps::Int=30, 
    crf::Int=23)
    
    # Read data from MIC file
    data = readMIC(filename, groupname=groupname, datasetnum=datasetnum)

    # Save data to mp4 file
    if isnothing(savefilename)
        basefilename = split(filename, ".")[1]
        savefilename = basefilename * ".mp4"
    end

    SMLMVis.save_to_mp4(data, filename * ".mp4", fps=fps, crf=crf)

    return nothing
end
