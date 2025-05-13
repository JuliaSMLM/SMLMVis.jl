# Simple test for 2D rendering with the new Render module

using SMLMVis
using SMLMData
using Images
using Random

# Set random seed for reproducibility
Random.seed!(123)

# Create a simple 2D sample data
function create_test_data(n_particles=20, img_size=(128, 128))
    # Create emitters
    emitters = Vector{Emitter2DFit{Float64}}(undef, n_particles)
    
    # Pixel size in microns (100nm)
    pixel_size = 0.1
    
    # Fixed pattern of emitters in a 4x5 grid
    grid_size = (4, 5)
    spacing_x = img_size[1] * pixel_size / (grid_size[1] + 1)
    spacing_y = img_size[2] * pixel_size / (grid_size[2] + 1)
    
    # Parameters for stronger signal
    base_photons = 10000.0
    psf_width = 0.2  # 200nm
    
    # Create a grid of emitters
    idx = 1
    for row in 1:grid_size[2]
        for col in 1:grid_size[1]
            if idx <= n_particles
                # Calculate position on grid
                x = col * spacing_x
                y = row * spacing_y
                
                # Vary photon count based on position
                intensity_factor = 0.5 + 0.5 * (col / grid_size[1]) * (row / grid_size[2])
                photons = base_photons * intensity_factor
                
                # Background level
                bg = 10.0
                
                # Uncertainties
                σ_photons = sqrt(photons)
                σ_bg = 1.0
                
                # Frame number (time point) - vary by position
                frame = ((row-1) * grid_size[1] + col) % 10 + 1
                
                # Create emitter with strong signal
                emitters[idx] = Emitter2DFit{Float64}(
                    x, y,                # x, y coords
                    photons, bg,         # photons, background
                    psf_width, psf_width, # position uncertainties
                    σ_photons, σ_bg;     # photon/bg uncertainties
                    frame = frame,       # frame number
                    dataset = 1,         # dataset ID
                    track_id = idx,      # trajectory ID
                    id = idx             # unique ID
                )
                idx += 1
            end
        end
    end
    
    # Create camera
    camera = IdealCamera(img_size[1], img_size[2], pixel_size)
    
    # Create BasicSMLD
    return BasicSMLD(emitters, camera, 10, 1, Dict{String,Any}())
end

println("Creating test 2D SMLD data...")
# Use fewer emitters since we're now using a grid layout
smld = create_test_data(20)
println("Created SMLD with $(length(smld.emitters)) emitters")

println("\nRendering with default settings (single color)...")
img1 = render(smld; zoom=20)
save(joinpath("dev", "output", "render2d_default.png"), img1)
println("Saved to dev/output/render2d_default.png")

println("\nRendering with color by photon count...")
img2 = render(smld; zoom=20, color_by=:photons, colormap=:viridis)
save(joinpath("dev", "output", "render2d_photons.png"), img2)
println("Saved to dev/output/render2d_photons.png")

println("\nRendering with color by frame number...")
img3 = render(smld; zoom=20, color_by=:frame, colormap=:plasma)
save(joinpath("dev", "output", "render2d_frames.png"), img3)
println("Saved to dev/output/render2d_frames.png")

println("\nRendering with logarithmic contrast adjustment...")
img4 = render(smld; 
    zoom=20,
    color_by=:photons,
    colormap=:inferno,
    contrast=(method=:log, clip=0.98)
)
save(joinpath("dev", "output", "render2d_log.png"), img4)
println("Saved to dev/output/render2d_log.png")

println("\nRendering with square root contrast adjustment...")
img5 = render(smld; 
    zoom=20,
    color_by=:photons,
    colormap=:inferno,
    contrast=(method=:sqrt, clip=0.98)
)
save(joinpath("dev", "output", "render2d_sqrt.png"), img5)
println("Saved to dev/output/render2d_sqrt.png")

println("\nRendering with higher zoom factor...")
img6 = render(smld; zoom=40, color_by=:photons, colormap=:viridis)
save(joinpath("dev", "output", "render2d_zoom40.png"), img6)
println("Saved to dev/output/render2d_zoom40.png")

println("\nDone! Created 6 test images.")