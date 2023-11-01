using Revise 
using HDF5
using SMLMVis
using ImageView

# # TIRF Data 1 sequence
dirname = "Y:/Personal Folders/Ellyse/TIRF A431 Cells EGF-AF555 10_27_23"
filename = "Cell9_561laser5mW_exp0.05_300pM-2023-10-27-14-52-17"
fn = joinpath(dirname, filename * ".h5")

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)

# groupname="Channel01/Zposition001"
    
# g =file[groupname]
#    # Get list of object names in group
# object_names = keys(file[groupname])

# #check each object is a dataset
# n_datasets = 0
# for i in 1:length(object_names)
#     if isa(g[object_names[i]], HDF5.Dataset)
#        n_datasets += 1
#     end
# end
# n_datasets

# close(file)

SMLMVis.MIC.count_datasets(fn)
SMLMVis.MIC.isMIC(fn)
data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
SMLMVis.MIC.mic2mp4(fn; crf = 1, fps = 1 )
imshow(data)


# #TIRF Data Multiple sequences
# dirname = "Y:/Personal Folders/Ellyse/DNA-PAINT Testing/21-06-24"
# filename = "DNA-PAINT40R-2021-6-24-15-1-3"

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)
# close(file)


# SeqSRData
dirname = "P:/IgE_Integrin/23-09-07_IgE647_IntegrinB1-647/Resting/Cell_01/Label_01"
filename = "Data_2023-9-11-12-27-31.h5"
fn = joinpath(dirname, filename)

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)

# # Count number of datasets in group
#  groupname = joinpath("Channel01", "Zposition001")
#  groupname = "Channel01/Zposition001"

#   # Get list of object names in group
#   object_names = names(file[groupname])


#  # Get list of object names in group
#  object_names = keys(file[groupname])
#  n_datasets = length(object_names)
# close(file)


SMLMVis.MIC.count_datasets(fn)

SMLMVis.MIC.isMIC(fn)

data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
SMLMVis.MIC.normalize!(data)

im = data[:,:,1:1000]

# @profview imgstack = SMLMVis.arr2imgstack(data);

# SMLMVis.save_to_mp4("test.mp4", im, fps=30, crf=23)

@time SMLMVis.MIC.mic2mp4(fn)

