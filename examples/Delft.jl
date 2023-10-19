using JLD2
using FileIO
using SMLMData
using Images
using SMLMVis

dirname = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data2"
file = "Data2-2023-10-6-17-11-54deepfit1.jld2"
filepath = joinpath(dirname, file)
# Load the file
data = load(filepath)
#varnames = keys(data) 
# Render the blobs
smld = data["smld"]
out = SMLMVis.render_blobs(smld; zoom = 20)

# z_range = (-0.5,0.5)