# using Revise 
# using HDF5
using SMLMVis
# using ImageView

# # TIRF Data 1 sequence
#dirname = "C:/Users/klidke/Downloads"
dirname = "//64.106.63.182/adapt-lrs/projects/cells-labeling/Data/PAIS TIRF Data/TIRF Cho Cells EGFR ZEO anitALFA-ATTO488 1_26_24"

filename = "Cell11_561laser2mW_exp0.1_3nM-2024-1-26-15-47-19"
fn = joinpath(dirname, filename * ".h5")

SMLMVis.MIC.count_datasets(fn)
SMLMVis.MIC.isMIC(fn)
data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1);)
mic2mp4(fn; fps = 10, percentilerange = 0.99, zoom = 4, frame_range = 1:500)
# imshow(data)


#dirname = "C:/Users/klidke/Downloads"
#dirname = "Y:/Personal Folders/Ellyse/TIRF A431 Cells EGF-AF555 10_27_23"
#files = filter(f -> endswith(f, ".h5"), readdir(dirname))
#fullfiles = dirname .* "/" .* files
#mic2mp4.(fullfiles; fps = 20, percentilerange = 0.99, zoom = 4)

