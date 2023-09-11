using Revise 
using HDF5
using SMLMVis


# # TIRF Data 1 sequence
# dirname = "Y:/Personal Folders/Ellyse/ALFA Tag 488 Hela EGFR"
# filename = "Cell1-2023-9-6-14-51-2"
# fn = joinpath(dirname, filename * ".h5")

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)
# close(file)


# #TIRF Data Multiple sequences
# dirname = "Y:/Personal Folders/Ellyse/DNA-PAINT Testing/21-06-24"
# filename = "DNA-PAINT40R-2021-6-24-15-1-3"

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)
# close(file)

# SeqSRData
dirname = "P:/IgE_Integrin/23-09-07_IgE647_IntegrinB1-647/5minDNP-BSA/Cell_01/Label_02"
filename = "Data_2023-9-8-20-12-46.h5"
fn = joinpath(dirname, filename)

# file = h5open(fn, "r")
# HDF5.show_tree(file)
# # data = h5read(file)

#  # Get list of object names in group
#  object_names = names(file[groupname])

#  # Count number of datasets in group
#  groupname = joinpath("Channel01", "Zposition001")
#  groupname = "Channel01/Zposition001"

#  # Get list of object names in group
#  object_names = keys(file[groupname])
#  n_datasets = length(object_names)
# close(file)


SMLMVis.MIC.count_datasets(fn)

SMLMVis.MIC.isMIC(fn)

data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
SMLMVis.MIC.normalize!(data)

SMLMVis.MIC.mic2mp4(fn, framenormalize=false)

