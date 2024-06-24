using Revise
using SMLMVis
using FileIO
using SMLMData
using Images
#using CairoMakie
#using ImageView
using GLMakie
using Statistics
using JLD2 
# pathname  = "C:\\Data"
# filename = "Data2-2023-9-19-22-25-4deepfit1.jld2"
# filename = "Data2-2023-10-6-17-11-54deepfit1.jld2"



# My changes goes here
pathname  = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5"
filename = "data.jld2"

fn = joinpath(pathname,filename)
outfile = joinpath(pathname,splitext(filename)[1]*".png")

data = load(fn)
loc_data = data["loc_data"]
println("Type of loc_data:", typeof(loc_data))
#dump(loc_data)
#crlb = loc_data["crlb"]
#smld = data["loc_data"]
#println(keys(loc_data))
#loc_data["datasize"] = [256, 256]
nlocs = length(loc_data["x"])
@info "There are $nlocs localizations"
# converting smld dict to match function signature:
# Extract values from the smld dictionary

#x_range = (1, loc_data["datasize"][2])
#y_range = (1, loc_data["datasize"][1])

x_raw = loc_data["x"]
y_raw = loc_data["y"]
z_raw = loc_data["z"]  # nm ??


σ_x_raw = loc_data["crlb"][:, 1]
σ_y_raw = loc_data["crlb"][:, 2]
σ_z_raw = loc_data["crlb"][:, 5]  # check - is this in nm ??
σ_photons_raw = loc_data["crlb"][:, 3] #  
σ_bg_raw = loc_data["crlb"][:, 4] 

# Threshold 
σ_xy_max = .2
σ_z_max = 240
mask = (σ_x_raw .< σ_xy_max) .& (σ_y_raw .< σ_xy_max) .& (σ_z_raw .< σ_z_max)

x = x_raw[mask]
y= y_raw[mask]
z = Float64.(z_raw[mask])
σ_x = σ_x_raw[mask]
σ_y = σ_y_raw[mask]
σ_z = σ_z_raw[mask]
photons = loc_data["photon"][mask]
σ_photons = σ_photons_raw[mask]
bg = loc_data["bg"][mask]
σ_bg = σ_bg_raw[mask]
# create empty array
connectID = zeros(Int, length(x))
framenum = zeros(Int, length(x))
datasetnum = zeros(Int, length(x))
datasize = [256; 256]
nframes = 1
ndatasets = 1

smld = SMLMData.SMLD3D(1) # 6323878
smld.x = x
smld.y = y
smld.z = z
smld.σ_x = σ_x
smld.σ_y = σ_y
smld.σ_z = σ_z
smld.photons = photons
smld.σ_photons = σ_photons
smld.bg = bg
smld.σ_bg = σ_bg
smld.framenum = framenum
smld.datasetnum = datasetnum
smld.datasize = datasize
smld.nframes = nframes
smld.ndatasets = ndatasets
smld.datafields = (:connectID, :x, :y, :z, :σ_x, :σ_y, :σ_z, :photons, :σ_photons, :bg, :σ_bg, :framenum, :datasetnum)
smld  

# Optional parameters
normalization = :integral
n_sigmas = 3
colormap = :jet
#z_range = (0.0, 120.0)
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
zoom = 10
percentile_cutoff = 0.90

# Call the render_blobs function
out, (cm,z_range) = render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
display(out)
save(outfile, out)


# Use GLMakie for visualization
fig = Figure(resolution = (800, 800))
ax = GLMakie.Axis(fig[1, 1], title = "SMLM Visualization")
image!(ax, out, colormap = :jet)
Colorbar(fig[1, 2], colormap = :jet, label = "Z Value")
display(fig)

# Define the output file path
output_path = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"

# Save the `smld` dictionary to a JLD2 file
@save output_path smld

# Create the GLMakie GUI figure
fig = Figure(resolution = (800, 800))

# Create a central container for the label
label_layout = GridLayout()
fig[1, 1] = label_layout

# Add a label to display the status at the top, centered in the figure
status_label = Label(fig, "SR visualization", halign = :center)
label_layout[1, 1] = status_label

# Create a grid layout for the buttons at the bottom
button_layout = GridLayout()
fig[3, 1] = button_layout

# Create a button for loading the file at the bottom left
load_button = Button(fig, label = "Load smld.jld2")
button_layout[1, 1] = load_button

# Create a button for rendering the image at the bottom right
render_button = Button(fig, label = "Render Image")
button_layout[1, 2] = render_button

# Add an Axis directly to the main figure for displaying the image
image_axis = Axis(fig, title = "Rendered Image", aspect = DataAspect())
fig[2, 1] = image_axis

# Adjust the layout to give more space to the image axis
fig.layout[1, 1] = label_layout
fig.layout[3, 1] = button_layout

# Adjust row and column sizes
fig.layout.rowsizes = [Relative(0.1), Relative(0.8), Relative(0.1)]  # Give 80% of the height to the image axis row
fig.layout.colsizes = [Relative(1.0)]  # Single column, full width

# Define a callback function to load smld data
function load_smld_data(button)
    global smld  # Use the global smld defined earlier
    status_label.text = "SMLD data loaded"
end

# Assign the callback to the load button
on(load_button.clicks) do _
    load_smld_data(load_button)
end

# Define a callback function to render and display the image
function render_image(button)
    global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff

    if !isa(z_range, Tuple{Real, Real})
        error("z_range is not of the correct type. It should be a tuple of two real numbers.")
    end
    
    out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
    
    # Replace the previous image in the axis
    image!(image_axis, out, show_axes = false)
    status_label.text = "Image rendered"
end

# Assign the callback to the render button
on(render_button.clicks) do _
    render_image(render_button)
end

# Display the figure
display(fig)




















































function read_jld2_keys(file_path::String)
    # Open the .jld2 file in read mode
    jld2_file = jldopen(file_path, "r")

    # Get the keys of the .jld2 file
    keys = JLD2.keys(jld2_file)

    # Print the keys
    println("Keys in the file: ", collect(keys))

    # Close the file
    close(jld2_file)
end

file_path = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"
read_jld2_keys(file_path)