# Basic test to verify SMLMVis functionality

using SMLMVis
using SMLMData
using Images

println("Creating a simple 2D test dataset...")

# Create a simple camera
camera = IdealCamera(100, 100, 0.1)  # 100x100 pixels, 100nm pixel size

# Create multiple emitters with strong signal
emitters = [
    # Center emitter
    Emitter2DFit{Float64}(
        5.0, 5.0,                # x, y coords (microns)
        10000.0, 10.0,           # photons (increased), background
        0.15, 0.15,              # position uncertainties (microns)
        50.0, 2.0;               # photon/bg uncertainties
        frame = 1,               # frame number
        dataset = 1,             # dataset ID
        track_id = 1,            # trajectory ID
        id = 1                   # unique ID
    ),
    # Another emitter
    Emitter2DFit{Float64}(
        3.0, 3.0,                # x, y coords (microns)
        8000.0, 10.0,            # photons, background
        0.15, 0.15,              # position uncertainties (microns)
        50.0, 2.0;               # photon/bg uncertainties
        frame = 1,               # frame number
        dataset = 1,             # dataset ID
        track_id = 2,            # trajectory ID
        id = 2                   # unique ID
    ),
    # A third emitter
    Emitter2DFit{Float64}(
        7.0, 7.0,                # x, y coords (microns)
        12000.0, 10.0,           # photons, background
        0.15, 0.15,              # position uncertainties (microns)
        50.0, 2.0;               # photon/bg uncertainties
        frame = 1,               # frame number
        dataset = 1,             # dataset ID
        track_id = 3,            # trajectory ID
        id = 3                   # unique ID
    )
]

# Create an SMLD
smld = BasicSMLD(emitters, camera, 1, 1, Dict{String,Any}())

println("Rendering with default settings...")
println("SMLD has $(length(smld.emitters)) emitters")
println("Emitter coordinates (microns):")
for (i, e) in enumerate(smld.emitters)
    println("  $i: ($(e.x), $(e.y)) with $(e.photons) photons")
end

# Render with higher contrast and increased photon values
println("Rendering image with adjusted settings for better visibility...")
img = render(smld; 
    zoom=8,                      # Reduced zoom for larger blobs
    contrast=(method=:linear, clip=0.5),
    n_sigmas=6.0,                # Increased sigma to make blobs larger
    normalization=:maximum       # Use maximum normalization for stronger signal
)
output_path = joinpath("dev", "output", "test_basic.png")
save(output_path, img)
println("Saved to $output_path")

# Also create a version with color to easily see the different emitters
println("Creating colored version...")
img_color = render(smld; 
    zoom=8, 
    color_by=:photons,           # Color by photon count
    colormap=:plasma,            # Plasma colormap for good visibility
    contrast=(method=:linear, clip=0.5),
    n_sigmas=6.0,
    normalization=:maximum
)
output_path_color = joinpath("dev", "output", "test_basic_color.png")
save(output_path_color, img_color)
println("Saved to $output_path_color")

# Create a zoomed in version to better see the blobs
println("Creating zoomed version...")
img_zoom = render(smld; 
    zoom=30, 
    color_by=:photons,
    colormap=:viridis,
    contrast=(method=:linear, clip=0.5),
    n_sigmas=6.0,
    normalization=:maximum
)
output_path_zoom = joinpath("dev", "output", "test_basic_zoom.png")
save(output_path_zoom, img_zoom)
println("Saved to $output_path_zoom")

println("All tests completed successfully!")