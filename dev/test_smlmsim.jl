# test_smlmsim.jl
# Run with: julia dev/test_smlmsim.jl (or press Run in VSCode)

using Pkg
Pkg.activate("dev")
Pkg.instantiate()

# Load required packages
using Revise
using SMLMSim
using SMLMData
using Images
using SMLMVis

# Create output directory
mkpath("dev/output")

# Set up simulation parameters for 2D
params = SMLMSim.StaticSMLMParams(
    density=25.0,             # Higher density of molecules per μm²
    σ_psf=0.15,               # PSF width in μm
    minphotons=100.0,         # Minimum photons for localization
    ndatasets=5,              # Number of datasets
    nframes=5000,             # Number of frames
    framerate=50.0,           # Frame rate in Hz
    ndims=2,                  # 2D simulation
    zrange=[-1.0, 1.0]        # Z range in microns
)

# Run the simulation
println("Running simulation...")
smld_true, smld_model, smld_noisy = SMLMSim.simulate(params)
println("Simulation complete!")
println("Generated $(length(smld_noisy.emitters)) emitters")

# Test only default zoom and zoom=5 with different coloring options
println("Testing different rendering options...")

# Render with default settings (zoom=20)
println("Rendering with default settings (zoom=20)...")
img_default = render(smld_noisy)
save("dev/output/default_render.png", img_default)
println("Saved to dev/output/default_render.png")

# Render with zoom=5
println("Rendering with zoom=5...")
img_zoom5 = render(smld_noisy; zoom=5)
save("dev/output/zoom5_render.png", img_zoom5)
println("Saved to dev/output/zoom5_render.png")

# Render with default settings but colored by photons (a common property that always exists)
println("Rendering with coloring by photons...")
img_photons = render(smld_noisy; 
    color_by=:photons,          # Color by photon count
    colormap=:turbo,            # Use turbo colormap for good differentiation
    contrast=(method=:log, clip=0.9999),  # Logarithmic contrast with strong clip
    normalization=:maximum,     # Use maximum normalization for better color visibility
    zoom=20                     # Ensure we use a high zoom for better visibility
)
save("dev/output/colored_by_photons.png", img_photons)
println("Saved to dev/output/colored_by_photons.png")

# Render with zoom=5 and colored by photons
println("Rendering zoom=5 with coloring by photons...")
img_photons_zoom5 = render(smld_noisy; 
    zoom=5,                    # Zoom factor
    color_by=:photons,         # Color by photon count
    colormap=:turbo,           # Use turbo colormap for good differentiation
    contrast=(method=:log, clip=0.9999),  # Logarithmic contrast with strong clip
    normalization=:maximum     # Use maximum normalization for better color visibility
)
save("dev/output/zoom5_colored_by_photons.png", img_photons_zoom5)
println("Saved to dev/output/zoom5_colored_by_photons.png")

println("All tests completed. Check the dev/output directory for results.")

