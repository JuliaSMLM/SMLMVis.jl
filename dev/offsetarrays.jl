using Revise
using SMLMVis
using Images
# using ColorSchemes

sz = 256

n_blobs = Int(1e4)
x = rand(1:sz, n_blobs)
y = rand(1:sz, n_blobs)
z = rand(-1:.01:1, n_blobs)
σ_x = rand(n_blobs)
σ_y = rand(n_blobs)

@time out = render_blobs((1,sz), (1,sz), 
x, y, σ_x, σ_y; z = z)

save("test.png", out)

