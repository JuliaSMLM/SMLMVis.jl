using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
using CairoMakie
using ImageView
using Statistics 
# pathname  = "C:\\Data"
# filename = "Data2-2023-9-19-22-25-4deepfit1.jld2"
# filename = "Data2-2023-10-6-17-11-54deepfit1.jld2"


pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/"
filename = "data.jld2"

fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)
#varnames = keys(data)
#smld = data["smld"]
#nlocs = length(smld.x)
#@info "There are $nlocs localizations"
smld = data["loc_data"]
smld["datasize"] = [256, 256]
nlocs = length(smld["x"])
@info "There are $nlocs localizations"

# out = render_blobs(smld; zoom = 4)
# save(outfile, out[1])

# hist(smld.y; bins = 100)
# hist(smld.z; bins = 100)
# hist(smld.x-floor.(smld.x); bins = 100)
# hist(smld.σ_z; bins = 100)
# hist(smld.σ_x; bins = 100)

# hist(smld.photons; bins = 100)

# sum(isapprox.(smld.x-floor.(smld.x),1; atol = 0.01))
# sum(isapprox.(smld.x-floor.(smld.x),0; atol = 0.01))

# Filter Localizations 

# rejected localizations
m1 = isapprox.(smld.x-floor.(smld.x),1; atol = 0.01)
m2 = isapprox.(smld.x-floor.(smld.x),0; atol = 0.01)
m3 = isapprox.(smld.y-floor.(smld.y),1; atol = 0.01)
m4 = isapprox.(smld.y-floor.(smld.y),0; atol = 0.01)
σ_tol = 0.5
ms = (smld.σ_y .> σ_tol) .|| (smld.σ_x .> σ_tol)

# Mask for accepted localizations
mask = .!m1 .&& .!m2 .&& .!m3 .&& .!m4 .&& .!ms 

smld_filtered = deepcopy(smld)

smld_filtered.x = smld.x[mask]
smld_filtered.y = smld.y[mask]
smld_filtered.z = smld.z[mask]
smld_filtered.σ_x = smld.σ_x[mask]
smld_filtered.σ_y = smld.σ_y[mask]
smld_filtered.σ_z = smld.σ_z[mask]

# hist(smld_filtered.σ_x; bins = 100)
# hist(smld_filtered.σ_y; bins = 100)
# hist(smld_filtered.z; bins = 100)

max_sigma = max(maximum(smld_filtered.σ_x), maximum(smld_filtered.σ_y))
min_sigma = min(minimum(smld_filtered.σ_x), minimum(smld_filtered.σ_y))


nlocs = length(smld_filtered.x)
@info "There are $nlocs localizations after filtering"

# converting smld dict to match function signature:
# Extract values from the smld dictionary
x_range = (1, smld["datasize"][1])
y_range = (1, smld["datasize"][2])
x = smld["x"]
y = smld["y"]
σ_x = smld["crlb"][:, 1]
σ_y = smld["crlb"][:, 2]
z = smld["z"]  # Assuming you want to use the z values

# Optional parameters
normalization = :integral
n_sigmas = 3
colormap = :jet
z_range = (quantile(smld["z"], 0.01), quantile(smld["z"], 0.99))
zoom = 4
percentile_cutoff = 0.99

# Call the render_blobs function
out, (cm,z_range)= render_blobs(
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
    zoom=4,
    percentile_cutoff=0.99)

## 

#out, (cm,z_range)= render_blobs(smld_filtered; zoom = 4)
out, (cm,z_range)= render_blobs(smld; zoom = 4)

# calculate quantile range of z 
z_range = (quantile(smld_filtered.z, 0.01), quantile(smld_filtered.z, 0.99))
out, (cm,z_range)= render_blobs(smld_filtered; zoom = 4, z_range, percentile_cutoff = 0.98)
display(out)
save(outfile, out)


