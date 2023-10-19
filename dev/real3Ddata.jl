using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
using CairoMakie

pathname  = "C:\\Data"
filename = "Data2-2023-9-19-22-25-4deepfit1.jld2"
fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)

smld = data["smld"]
smld.datasize = [512, 512]
nlocs = length(smld.x)
@info "There are $nlocs localizations"

# out = render_blobs(smld; zoom = 4)
# save(outfile, out[1])

hist(smld.y; bins = 100)
hist(smld.z; bins = 100)
hist(smld.x-floor.(smld.x); bins = 100)
hist(smld.σ_z; bins = 100)
hist(smld.σ_x; bins = 100)

hist(smld.photons; bins = 100)

sum(isapprox.(smld.x-floor.(smld.x),1; atol = 0.01))
sum(isapprox.(smld.x-floor.(smld.x),0; atol = 0.01))

m1 = isapprox.(smld.x-floor.(smld.x),1; atol = 0.01)
m2 = isapprox.(smld.x-floor.(smld.x),0; atol = 0.01)
m3 = isapprox.(smld.y-floor.(smld.y),1; atol = 0.01)
m4 = isapprox.(smld.y-floor.(smld.y),0; atol = 0.01)


mask = .!m1 .&& .!m2 .&& .!m3 .&& .!m4 
sum(mask)

smld.x = smld.x[mask]
smld.y = smld.y[mask]
smld.z = smld.z[mask]
smld.σ_x = smld.σ_x[mask]
smld.σ_y = smld.σ_y[mask]
smld.σ_z = smld.σ_z[mask]

out = render_blobs(smld; zoom = 4)
save(outfile, out[1])




