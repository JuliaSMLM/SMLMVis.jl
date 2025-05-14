# test_rainbow.jl
# A specific test to show how coloring by dataset number works
using Pkg
Pkg.activate(".")

using SMLMData
using SMLMVis
using Images

# Create output directory
mkpath("dev/output")

# Create a synthetic dataset with emitters in different parts of the camera
# and with different dataset numbers to clearly see the coloring
function create_test_dataset()
    # Create camera
    camera = SMLMData.IdealCamera(128, 128, 0.1)
    
    # Get camera dimensions from pixel edges
    camera_width = length(camera.pixel_edges_x) - 1
    camera_height = length(camera.pixel_edges_y) - 1
    
    # Initialize array to hold emitters
    emitters = []
    
    # Create a grid of emitters, each region with a different dataset number
    regions = 5
    emitters_per_region = 300
    
    for region in 1:regions
        region_width = camera_width / regions
        region_height = camera_height
        
        for i in 1:emitters_per_region
            # Calculate position within the region
            region_start_x = (region - 1) * region_width
            x = region_start_x + rand() * region_width
            y = rand() * region_height
            
            # Create basic emitter
            emitter = SMLMData.Emitter2D(
                x * camera.pixel_edges_x[2],  # Convert to microns (x)
                y * camera.pixel_edges_y[2],  # Convert to microns (y)
                1000.0  # photons
            )
            
            # Add dataset metadata
            dataset_info = Dict(:dataset => region)
            emitter = SMLMData.with_metadata(emitter, dataset_info)
            
            push!(emitters, emitter)
        end
    end
    
    # Create SMLD2D object
    smld = SMLMData.SMLD2D(emitters, camera)
    
    return smld
end

# Create test dataset
println("Creating test dataset...")
smld = create_test_dataset()
println("Created $(length(smld.emitters)) emitters")

# Render with zoom=5 and colored by dataset number
println("Rendering with coloring by dataset...")
img_dataset = render(smld; 
    zoom=10,                   # Zoom factor
    color_by=:dataset,         # Color by dataset number
    colormap=:hsv,             # Use HSV colormap for distinct colors
    contrast=(method=:linear, clip=0.9999),  # Strong contrast
    normalization=:maximum     # Use maximum normalization for better visibility
)
save("dev/output/rainbow_dataset.png", img_dataset)
println("Saved to dev/output/rainbow_dataset.png")

println("Done!")