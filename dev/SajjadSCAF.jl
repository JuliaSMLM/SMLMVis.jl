using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
using CairoMakie
#using ImageView
using Statistics 
# pathname  = "C:\\Data"
# filename = "Data2-2023-9-19-22-25-4deepfit1.jld2"
# filename = "Data2-2023-10-6-17-11-54deepfit1.jld2"



# My changes goes here
pathname  = "/mnt/nas/lidkelab/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/"
filename = "data.jld2"

fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)
smld = data["loc_data"]
smld["datasize"] = [256, 256]
nlocs = length(smld["x"])
@info "There are $nlocs localizations"
# converting smld dict to match function signature:
# Extract values from the smld dictionary
x_range = (1, smld["datasize"][2])
y_range = (1, smld["datasize"][1])

x_raw = smld["x"]
y_raw = smld["y"]
z_raw = smld["z"]  # nm ??


σ_x_raw = smld["crlb"][:, 1]
σ_y_raw = smld["crlb"][:, 2]
σ_z_raw = smld["crlb"][:, 5]  # check - is this in nm ??

# Threshold 
σ_xy_max = .2
σ_z_max = 240
mask = (σ_x_raw .< σ_xy_max) .& (σ_y_raw .< σ_xy_max) .& (σ_z_raw .< σ_z_max)

x = x_raw[mask]
y= y_raw[mask]
σ_x = σ_x_raw[mask]
σ_y = σ_y_raw[mask]
z = Float64.(z_raw[mask])
σ_z = σ_z_raw[mask]

# Optional parameters
normalization = :integral
n_sigmas = 3
colormap = :jet
z_range = (quantile(smld["z"], 0.01), quantile(smld["z"], 0.99))
zoom = 4
percentile_cutoff = 0.99

# Call the render_blobs function
out, (cm,z_range) = SMLMVis.render_blobs(
    x_range,
    y_range,
    x,
    y,
    σ_x,
    σ_y,
    normalization= :integral,
    n_sigmas=3,
    colormap=:jet,
    z=z,
    z_range=z_range,
    zoom=10,
    percentile_cutoff=0.99)

display(out)
save(outfile, out)
