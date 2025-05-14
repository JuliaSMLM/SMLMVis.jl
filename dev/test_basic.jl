# test_basic.jl
# Tests the coordinate fix with a really simple pattern
using Pkg
Pkg.activate(".")

using SMLMData
using SMLMVis
using Random
using Images

# Create output directory
mkpath("dev/output")

# Create a test pattern with emitters distributed in a grid pattern
function create_test_grid()
    # Create a camera
    camera = SMLMData.IdealCamera(128, 128, 0.1)
    
    # Create emitters in a grid pattern
    emitters = []
    
    # Number of points in each dimension
    grid_size = 10
    
    # Spacing between grid points in physical units (microns)
    spacing_x = camera.pixel_edges_x[end] / (grid_size + 1)
    spacing_y = camera.pixel_edges_y[end] / (grid_size + 1)
    
    for i in 1:grid_size
        for j in 1:grid_size
            # Calculate position
            x = i * spacing_x
            y = j * spacing_y
            
            # Create emitter with varying photon counts
            photons = 500.0 + 500.0 * ((i + j) / (2 * grid_size))
            
            emitter = SMLMData.Emitter2D(x, y, photons)
            push!(emitters, emitter)
        end
    end
    
    # Create BasicSMLD object
    smld = SMLMData.BasicSMLD(emitters, camera, 1, 1)
    
    return smld
end

# Create test dataset
println("Creating test grid...")
smld = create_test_grid()
println("Created $(length(smld.emitters)) emitters")

# Render with default settings
println("Rendering with default settings...")
img_default = render(smld)
save("dev/output/grid_default.png", img_default)
println("Saved to dev/output/grid_default.png")

# Render with zoom=5
println("Rendering with zoom=5...")
img_zoom5 = render(smld; zoom=5)
save("dev/output/grid_zoom5.png", img_zoom5)
println("Saved to dev/output/grid_zoom5.png")

# Render with color by photons (should show a gradient)
println("Rendering with coloring by photons...")
img_photons = render(smld;
    color_by=:photons,  # Color by photon count
    colormap=:viridis,  # Use viridis colormap
    contrast=(method=:linear, clip=0.999),  # Linear contrast
    normalization=:maximum  # Maximum normalization
)
save("dev/output/grid_colored.png", img_photons)
println("Saved to dev/output/grid_colored.png")

println("All tests completed. Check the dev/output directory for results.")