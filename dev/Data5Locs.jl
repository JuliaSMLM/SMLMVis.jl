using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
#using CairoMakie
#using ImageView
using GLMakie
using Statistics
using JLD2 
# pathname  = "C:\\Data"
# filename = "Data2-2023-9-19-22-25-4deepfit1.jld2"
# filename = "Data2-2023-10-6-17-11-54deepfit1.jld2"



# My changes goes here
pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5"
filename = "data.jld2"

fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)
loc_data = data["loc_data"]
println("Type of loc_data:", typeof(loc_data))
#dump(loc_data)
#crlb = loc_data["crlb"]
#smld = data["loc_data"]
#println(keys(loc_data))
#loc_data["datasize"] = [256, 256]
nlocs = length(loc_data["x"])
@info "There are $nlocs localizations"
# converting smld dict to match function signature:
# Extract values from the smld dictionary
x_range = (1, loc_data["datasize"][2])
y_range = (1, loc_data["datasize"][1])

x_raw = loc_data["x"]
y_raw = loc_data["y"]
z_raw = loc_data["z"]  # nm ??


σ_x_raw = loc_data["crlb"][:, 1]
σ_y_raw = loc_data["crlb"][:, 2]
σ_z_raw = loc_data["crlb"][:, 5]  # check - is this in nm ??
σ_photons_raw = loc_data["crlb"][:, 3] #  
σ_bg_raw = loc_data["crlb"][:, 4] 

# Threshold 
σ_xy_max = .2
σ_z_max = 240
mask = (σ_x_raw .< σ_xy_max) .& (σ_y_raw .< σ_xy_max) .& (σ_z_raw .< σ_z_max)

x = x_raw[mask]
y= y_raw[mask]
z = Float64.(z_raw[mask])
σ_x = σ_x_raw[mask]
σ_y = σ_y_raw[mask]
σ_z = σ_z_raw[mask]
photons = loc_data["photon"][mask]
σ_photons = σ_photons_raw[mask]
bg = loc_data["bg"][mask]
σ_bg = σ_bg_raw[mask]
# create empty array
connectID = zeros(Int, length(x))
framenum = zeros(Int, length(x))
datasetnum = zeros(Int, length(x))
datasize = [0; 0; 0]
nframes = 1
ndatasets = 1
# Create smld dictionary
smld_data = Dict(
    "connectID" => connectID,
    "x" => x,
    "y" => y,
    "z" => z,
    "σ_x" => σ_x,
    "σ_y" => σ_y,
    "σ_z" => σ_z,
    "photons" => photons,
    "σ_photons" => σ_photons,
    "bg" => bg,
    "σ_bg" => σ_bg,
    "framenum" => framenum,
    "datasetnum" => datasetnum,
    "datasize" => datasize,
    "nframes" => nframes,
    "ndatasets" => ndatasets,
    "datafields" => (:connectID, :x, :y, :z, :σ_x, :σ_y, :σ_z, :photons, :σ_photons, :bg, :σ_bg, :framenum, :datasetnum)
)

smld = SMLMData.SMLD3D(
    smld_data["connectID"],
    smld_data["x"],
    smld_data["y"],
    smld_data["z"],
    smld_data["σ_x"],
    smld_data["σ_y"],
    smld_data["σ_z"],
    smld_data["photons"],
    smld_data["σ_photons"],
    smld_data["bg"],
    smld_data["σ_bg"],
    smld_data["framenum"],
    smld_data["datasetnum"],
    smld_data["datasize"],
    smld_data["nframes"],
    smld_data["ndatasets"],
    smld_data["datafields"]
)
# Print the new dictionary to verify
# println(smld)

# Optional parameters
normalization = :integral
n_sigmas = 3
colormap = :jet
z_range = (0.0, 120.0)
#z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
zoom = 10
percentile_cutoff = 0.99

# Call the render_blobs function
out, (cm,z_range) = render_blobs(smld; normalization=normalization, n_sigmas=n_sigmas, colormap=colormap, z_range=z_range, zoom=zoom, percentile_cutoff=percentile_cutoff)
display(out)
save(outfile, out)

# using GLMakie
# Use GLMakie for visualization
# fig = Figure(resolution = (800, 800))
# ax = GLMakie.Axis(fig[1, 1], title = "SMLM Visualization")
# image!(ax, out, colormap = :jet)
# Colorbar(fig[1, 2], colormap = :jet, label = "Z Value")
# display(fig)

# Define the output file path
output_path = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"

# Save the `smld` dictionary to a JLD2 file
@save output_path smld


function read_jld2_keys(file_path::String)
    # Open the .jld2 file in read mode
    jld2_file = jldopen(file_path, "r")

    # Get the keys of the .jld2 file
    keys = JLD2.keys(jld2_file)

    # Print the keys
    println("Keys in the file: ", collect(keys))

    # Close the file
    close(jld2_file)
end

file_path = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"
read_jld2_keys(file_path)