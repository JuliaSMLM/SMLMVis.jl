using Revise
using SMLMVis
using Images
# using ColorSchemes

sz = 64

n_blobs = Int(1e5)
x = rand(1:.01:sz, n_blobs)
y = rand(1:.01:sz, n_blobs)
z = rand(-1:.01:1, n_blobs)
σ_x = rand(.1:.01:.2,n_blobs)
σ_y = rand(.1:.01:.2,n_blobs)

# 2D
@time out = render_blobs((1,sz), (1,sz), 
x, y, σ_x, σ_y; zoom = 20)
save("test2d.png", out)


# 3D
@time out = render_blobs((1,sz), (1,sz), 
x, y, σ_x, σ_y; z = z, zoom = 20, 
percentile_cutoff = 0.999)
save("test3d.png", out)
