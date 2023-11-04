using Revise 
using HDF5
using SMLMVis
using ImageView

# # TIRF Data 1 sequence
dirname = "C:/Users/klidke/Downloads"
filename = "Cell9_561laser5mW_exp0.05_300pM-2023-10-27-14-52-17"
fn = joinpath(dirname, filename * ".h5")

SMLMVis.MIC.count_datasets(fn)
SMLMVis.MIC.isMIC(fn)
data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
SMLMVis.MIC.mic2mp4(fn; fps = 20, percentilerange = 0.99, zoom = 4)
# imshow(data)

dirname = "C:/Users/klidke/Downloads"
files = filter(f -> endswith(f, ".h5"), readdir(dirname))

