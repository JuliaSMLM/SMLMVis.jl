using Revise 
using HDF5
using SMLMVis
using ImageView

# # TIRF Data 1 sequence
dirname = "Y:/Personal Folders/Ellyse/TIRF A431 Cells EGF-AF555 10_27_23"
filename = "Cell9_561laser5mW_exp0.05_300pM-2023-10-27-14-52-17"
fn = joinpath(dirname, filename * ".h5")

SMLMVis.MIC.isMIC(fn)
SMLMVis.MIC.isTIRF(fn)

SMLMVis.MIC.count_datasets(fn)
data = Float32.(SMLMVis.MIC.readMIC(fn, datasetnum=1));
SMLMVis.MIC.mic2mp4(fn; crf = 10, fps = 20)
imshow(data)

