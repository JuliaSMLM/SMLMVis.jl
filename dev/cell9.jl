# using Revise 
# using HDF5
using SMLMVis
# using ImageView

# # TIRF Data 1 sequence
dirname = "C:/Users/klidke/Downloads"
dirname = "Y:/Personal Folders/Ellyse/TIRF A431 Cells EGF-AF555 10_27_23"

filename = "Cell9_561laser5mW_exp0.05_300pM-2023-10-27-14-52-17"
fn = joinpath(dirname, filename * ".h5")

SMLMVis.MIC.count_datasets(fn)
SMLMVis.MIC.isMIC(fn)
data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
mic2mp4(fn; fps = 20, percentilerange = 0.99, zoom = 4, frame_range = 1:100)
# imshow(data)


dirname = "C:/Users/klidke/Downloads"
dirname = "Y:/Personal Folders/Ellyse/TIRF A431 Cells EGF-AF555 10_27_23"
files = filter(f -> endswith(f, ".h5"), readdir(dirname))
fullfiles = dirname .* "/" .* files
mic2mp4.(fullfiles; fps = 20, percentilerange = 0.99, zoom = 4)

