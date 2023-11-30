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


pathname  = "D:\\Data"
filename = "Cell8-2023-5-12-20-50-26deepfit1.jld2"

fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)

smld = data["smld"]
smld.datasize = [256, 256]
nlocs = length(smld.x)
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

out, (cm,z_range)= render_blobs(smld_filtered; zoom = 4)

# calculate quantile range of z 
z_range = (quantile(smld_filtered.z, 0.01), quantile(smld_filtered.z, 0.99))
out, (cm,z_range)= render_blobs(smld_filtered; zoom = 4, z_range, percentile_cutoff = 0.98)
display(out)
save(outfile, out)




