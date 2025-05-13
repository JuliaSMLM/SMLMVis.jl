# Test script for the new Render module

using SMLMVis
using SMLMData
using Images
using Random

# Set random seed for reproducibility
Random.seed!(42)

function create_sample_data_2d(n_particles=25, img_size=(100, 100), min_sigma=1.0, max_sigma=3.0)
    # Create emitters
    emitters = Vector{Emitter2DFit{Float64}}(undef, n_particles)
    
    # Pixel size in microns (100nm)
    pixel_size = 0.1
    
    # Create a grid pattern of emitters
    grid_size = (5, 5)  # 5x5 grid
    spacing_x = img_size[1] * pixel_size / (grid_size[1] + 1)
    spacing_y = img_size[2] * pixel_size / (grid_size[2] + 1)
    
    # Use strong signal
    base_photons = 10000.0
    
    # Create emitters in grid layout
    idx = 1
    for row in 1:grid_size[2]
        for col in 1:grid_size[1]
            if idx <= n_particles
                # Position in microns
                x = col * spacing_x
                y = row * spacing_y
                
                # PSF width varies across the grid
                sigma_factor = 0.5 + 0.5 * ((col + row) / (grid_size[1] + grid_size[2]))
                σ_x = (min_sigma + sigma_factor * (max_sigma - min_sigma)) * 0.1
                σ_y = σ_x  # Keep circular PSFs
                
                # Photon count varies diagonally
                intensity_factor = 0.3 + 0.7 * (col / grid_size[1]) * (row / grid_size[2])
                photons = base_photons * intensity_factor
                
                # Background level
                bg = 5.0
                
                # Uncertainties
                σ_photons = sqrt(photons)
                σ_bg = 1.0
                
                # Frame number varies across the grid
                frame = ((row-1) * grid_size[1] + col) % 10 + 1
                
                # Create emitter with strong signal
                emitters[idx] = Emitter2DFit{Float64}(
                    x, y,                # x, y coords
                    photons, bg,         # photons, background
                    σ_x, σ_y,            # position uncertainties
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
    return BasicSMLD(emitters, camera, n_particles, 1, Dict{String,Any}())
end

function create_sample_data_3d(n_particles=25, img_size=(100, 100, 20), min_sigma=1.0, max_sigma=3.0)
    # Create emitters
    emitters = Vector{Emitter3DFit{Float64}}(undef, n_particles)
    
    # Pixel size in microns (100nm)
    pixel_size = 0.1
    
    # Z range in microns with 5 layers
    z_layers = 5
    z_spacing = 0.2  # 200nm between z layers
    
    # Create a grid pattern of emitters
    grid_size = (5, 5)  # 5x5 grid
    spacing_x = img_size[1] * pixel_size / (grid_size[1] + 1)
    spacing_y = img_size[2] * pixel_size / (grid_size[2] + 1)
    
    # Use strong signal
    base_photons = 15000.0
    
    # Create 3D helix pattern
    idx = 1
    for layer in 1:z_layers
        # Z position for this layer, centered around 0
        z_position = (layer - (z_layers+1)/2) * z_spacing
        
        # For each layer, create a pattern
        for i in 1:5
            if idx <= n_particles
                # Create a circular pattern in each layer
                angle = 2π * i / 5
                radius = 0.4 * min(img_size[1], img_size[2]) * pixel_size
                
                # Position in microns
                x = img_size[1] * pixel_size / 2 + radius * cos(angle)
                y = img_size[2] * pixel_size / 2 + radius * sin(angle)
                z = z_position
                
                # PSF width varies with z
                depth_factor = 0.5 + 0.5 * (abs(z_position) / (z_layers * z_spacing / 2))
                σ_x = (min_sigma + depth_factor * (max_sigma - min_sigma)) * 0.1
                σ_y = σ_x
                σ_z = σ_x * 2.5  # Z uncertainty usually larger
                
                # Photon count varies with depth
                intensity_factor = 0.5 + 0.5 * (1.0 - abs(z_position) / (z_layers * z_spacing / 2))
                photons = base_photons * intensity_factor
                
                # Background level
                bg = 5.0
                
                # Uncertainties
                σ_photons = sqrt(photons)
                σ_bg = 1.0
                
                # Frame number
                frame = idx
                
                # Create emitter with strong signal
                emitters[idx] = Emitter3DFit{Float64}(
                    x, y, z,             # x, y, z coords
                    photons, bg,         # photons, background
                    σ_x, σ_y, σ_z,       # position uncertainties
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
    return BasicSMLD(emitters, camera, n_particles, 1, Dict{String,Any}("is_3d" => true))
end

println("Testing SMLMVis Render Module")
println("-----------------------------")

# Create test data
println("Creating sample 2D data...")
smld_2d = create_sample_data_2d(25, (100, 100))  # Use grid layout with fewer emitters
println("Created 2D data with $(length(smld_2d.emitters)) emitters")

println("Creating sample 3D data...")
smld_3d = create_sample_data_3d(25, (100, 100, 20))  # Use 3D layout with fewer emitters
println("Created 3D data with $(length(smld_3d.emitters)) emitters")

# Test 2D rendering
println("\nTesting 2D rendering:")
println("- Default rendering...")
img_2d_default = render(smld_2d)
save(joinpath("dev", "output", "test_2d_default.png"), img_2d_default)
println("  Saved to dev/output/test_2d_default.png")

println("- Intensity coloring...")
img_2d_intensity = render(smld_2d; color_by=:photons, colormap=:viridis)
save(joinpath("dev", "output", "test_2d_intensity.png"), img_2d_intensity)
println("  Saved to dev/output/test_2d_intensity.png")

println("- Higher zoom...")
img_2d_zoom = render(smld_2d; zoom=40, color_by=:photons, colormap=:plasma)
save(joinpath("dev", "output", "test_2d_zoom.png"), img_2d_zoom)
println("  Saved to dev/output/test_2d_zoom.png")

println("- Contrast adjustments...")
img_2d_contrast = render(smld_2d; 
    color_by=:photons, 
    colormap=:inferno, 
    contrast=(method=:log, clip=0.99)
)
save(joinpath("dev", "output", "test_2d_contrast.png"), img_2d_contrast)
println("  Saved to dev/output/test_2d_contrast.png")

# Test 3D rendering
println("\nTesting 3D rendering:")
println("- Z-coloring (default for 3D)...")
img_3d_z = render(smld_3d; color_by=:z)
save(joinpath("dev", "output", "test_3d_z.png"), img_3d_z)
println("  Saved to dev/output/test_3d_z.png")

println("- Different colormap...")
img_3d_alt = render(smld_3d; color_by=:z, colormap=:plasma)
save(joinpath("dev", "output", "test_3d_alt.png"), img_3d_alt)
println("  Saved to dev/output/test_3d_alt.png")

println("- Frame coloring...")
img_3d_t = render(smld_3d; color_by=:frame, colormap=:viridis)
save(joinpath("dev", "output", "test_3d_t.png"), img_3d_t)
println("  Saved to dev/output/test_3d_t.png")

# Test specialized rendering functions
println("\nTesting specialized rendering functions:")
println("- Using render_2d...")
img_2d_func = render_2d(smld_2d; zoom=20, colormap=:heat)
save(joinpath("dev", "output", "test_2d_func.png"), img_2d_func)
println("  Saved to dev/output/test_2d_func.png")

println("- Using render_3d on 3D data...")
img_3d_func = render_3d(smld_3d; zoom=20, colormap=:rainbow)
save(joinpath("dev", "output", "test_3d_func.png"), img_3d_func)
println("  Saved to dev/output/test_3d_func.png")

println("- Using render_3d on 2D data (should show warning)...")
img_2d_as3d = render_3d(smld_2d; zoom=20)
save(joinpath("dev", "output", "test_2d_as3d.png"), img_2d_as3d)
println("  Saved to dev/output/test_2d_as3d.png")

println("\nAll tests completed!")
println("Check the output images to verify rendering quality.")
println("Generated test images in dev/output/ directory.")