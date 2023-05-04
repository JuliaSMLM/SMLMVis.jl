# A GLMakie based image results viewer.
using SMLMVis
SV=SMLMVis

#include("gendatastack.jl")

# Use this script to develop, then put function in src/visualization

# Make grayscale heatmap
# fig=heatmap(data[:,:,1,1])

# Add slider that scrolls through data stack

predict = []

for i in 1:100
    for pos in SV.parse_gt(i, y)
        push!(
            predict,
            [
                pos[1] + rand(-0.5:0.00001:0.5), # x
                pos[2] + rand(-0.5:0.00001:0.5), # y
                rand(-1:0.0000000000000001:1), # z
                0, # N
                rand(1.0:0.1:3.0), # σx
                rand(1.0:0.1:3.0), # σy
                rand(0.1:0.1:3.0), # σz
                0, # σN
                i, # framenum
            ],
        )
    end
end

SV.display(data; predict=predict, gt=y, pixel_size=1.0)

# Add function that puts 'X' on gt location. Color code by z.
# https://makie.juliaplots.org/stable/examples/plotting_functions/scatter/

# scatter!(128*rand(10),128*rand(10),markersize =30, marker =:xcross, color=:yellow)
# fig

# Add function that plots circles with r=sigma. color code by z

