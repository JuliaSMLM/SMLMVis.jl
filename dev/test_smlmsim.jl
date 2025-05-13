# test_smlmsim.jl
# Set up dev environment
using Pkg
Pkg.activate("dev")

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
    density=50.0,             # Higher density of molecules per μm²
    σ_psf=0.15,               # PSF width in μm (slightly larger for better visibility)
    minphotons=100.0,         # Higher minimum photons for stronger signal
    ndatasets=1,              # Number of datasets
    nframes=1000,             # Number of frames
    framerate=50.0,           # Frame rate in Hz
    ndims=2,                  # 2D simulation
    zrange=[-1.0, 1.0]        # Z range in microns
)

# Run the simulation
println("Running simulation...")
smld_true, smld_model, smld_noisy = SMLMSim.simulate(params)
println("Simulation complete!")
println("Generated $(length(smld_noisy.emitters)) emitters")

# Render with default settings
println("Rendering with default settings...")
img_default = render(smld_noisy)
save("dev/output/default_render.png", img_default)
println("Saved to dev/output/default_render.png")

