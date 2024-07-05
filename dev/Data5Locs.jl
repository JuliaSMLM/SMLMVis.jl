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
using GeometryBasics 
using PolygonOps: inpolygon
using Distributions
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
mask_tsh = (σ_x_raw .< σ_xy_max) .& (σ_y_raw .< σ_xy_max) .& (σ_z_raw .< σ_z_max)

x = x_raw[mask_tsh]
y= y_raw[mask_tsh]
z = Float64.(z_raw[mask_tsh])
σ_x = σ_x_raw[mask_tsh]
σ_y = σ_y_raw[mask_tsh]
σ_z = σ_z_raw[mask_tsh]
photons = loc_data["photon"][mask_tsh]
σ_photons = σ_photons_raw[mask_tsh]
bg = loc_data["bg"][mask_tsh]
σ_bg = σ_bg_raw[mask_tsh]
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
# Calculate the range of smld.x and smld.y
img_width, img_height = size(out)
fig = Figure(resolution = (800, 800))
ax = GLMakie.Axis(fig[1, 1], title = "SMLM Visualization", limits = ((0, img_width), (0, img_height)))
image!(ax, out, colormap = :jet)
Colorbar(fig[1, 2], colormap = :jet, label = "Z Value")
display(fig)

# Define the output file path
output_path = "Y:/Projects/Super Critical Angle Localization Microscopy/Data/10-06-2023/Data5/smld.jld2"

# Save the `smld` dictionary to a JLD2 file
@save output_path smld

#============================================================#

# This part of script is plotting the x & y localizations within a polygon drawn on the rendered image

function get_polygon_points(p1, p2, p3, p4)
    return [p1, p2, p3, p4, p1]
end

function interactive_plot_with_polygon_tool(ax, image)
    points = Observable(Point2f0[])
    mask_ready = Observable(false)
    mask = Observable(Point2f0[])
    
    on(events(ax.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            pos = mouseposition(ax.scene)
            if all(pos .>= 0) && all(pos .<= Point2f0(size(image)))
                push!(points[], pos)
                notify(points)
                scatter!(ax, [pos], color=:red, markersize=4)
                if length(points[]) == 4
                    polygon_points = get_polygon_points(points[][1], points[][2], points[][3], points[][4])
                    lines!(ax, polygon_points, color=:red, linewidth=2)
                    println("Coordinates of the polygon: ", polygon_points)
                    mask[] = polygon_points
                    println("The mask is: ", mask[])
                    points[] = []
                    notify(points)
                    mask_ready[] = true
                end
            end
        end
    end
    
    return points, mask, mask_ready
end


# Function to extract polygon data and points
function extract_polygon_data_and_points(smld, polygon_points, zoom)
    println("Polygon points: ", polygon_points)

    # Initialize an empty array to store the localizations within the polygon
    global localizations = []

    # Iterate over each localization in smld.x and smld.y
    for i in 1:length(smld.x)
        # Scale the coordinates by zoom
        scaled_x = smld.x[i] * zoom
        scaled_y = smld.y[i] * zoom
        
        # Create a point from the scaled coordinates
        point = Point2f0(scaled_x, scaled_y)
        
        # Check if the localization is inside the polygon
        if inpolygon(point, polygon_points) != 0
            # If the localization is inside the polygon, add its coordinates to the localizations array
            push!(localizations, (smld.y[i], smld.x[i]))
            # push!(localizations, (smld.x[i], smld.y[i])) # original
        end
    end
    
    # Print the number of localizations inside the polygon
    println("Number of localizations inside the polygon: ", length(localizations))
    
    return localizations
end


# Function to render the image and enable interactive polygon drawing
function render_image(button)
    global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff

    if !isa(z_range, Tuple{Real, Real})
        error("z_range is not of the correct type. It should be a tuple of two real numbers.")
    end
    
    out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
    
    # Replace the previous image in the axis
    image!(image_axis, out', show_axes = false) # transpose out
    status_label.text = "Image rendered"

    # Enable mouse interaction
    points, mask, mask_ready = interactive_plot_with_polygon_tool(image_axis, out)

    # Observable to store points inside the polygon
    polygon_points_inside = Observable(Point2f0[])

    # Extract the data and points after the rectangle is defined
    on(mask_ready) do ready
        if ready
            localizations = extract_polygon_data_and_points(smld, mask[], zoom)
            polygon_points_inside[] = [Point2f0(loc[2] * zoom, loc[1] * zoom) for loc in localizations]
            println("Number of localizations inside the polygon: ", length(localizations))
            #println("Localizations inside the polygon: ", localizations)
        else
            println("No polygon was defined.")
        end
    end

    # Plot the localizations inside the polygon as red cross markers
    on(polygon_points_inside) do points
        scatter!(image_axis, points, markersize=5, marker=:circle, color=:red)
        #println("Number of localizations inside the polygon: ", length(points))
    end
end

# GUI setup
fig = Figure(resolution = (800, 800))

# Create a central container for the label
label_layout = GridLayout()
fig[1, 1] = label_layout

# Add a label to display the status at the top, centered in the figure
status_label = Label(fig, text = "SR visualization", halign = :center, valign = :center)
label_layout[1, 1] = status_label

# Create a grid layout for the render button at the bottom
button_layout = GridLayout()
fig[3, 1] = button_layout

# Create a button for rendering the image at the bottom center
render_button = Button(fig, label = "Render Image")
button_layout[1, 1] = render_button

# Add an Axis directly to the main figure for displaying the image
image_axis = GLMakie.Axis(fig, title = "Rendered Image", aspect = DataAspect())
fig[2, 1] = image_axis

# Adjust the layout to give more space to the image axis
fig.layout[1, 1] = label_layout
fig.layout[3, 1] = button_layout

# Adjust row and column sizes
fig.layout.rowsizes = [Relative(0.1), Relative(0.8), Relative(0.1)]
fig.layout.colsizes = [Relative(1.0)]

# Assign the callback to the render button
on(render_button.clicks) do _
    render_image(render_button)
end

display(fig)

#using CairoMakie
localizations
x_coords = [point[1] for point in localizations]
y_coords = [point[2] for point in localizations]
fig2 = Figure(resolution = (800, 600))
ax2 = CairoMakie.Axis(fig2[1, 1], title = "Localizations Scatter Plot", xlabel = "X", ylabel = "Y")
scatter!(ax2, x_coords, y_coords, markersize = 5, color = :blue) 
display(fig2)


#=======================================================================================================#

# Extract and Plot the smld.z within polygon
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))
function get_polygon_points(p1, p2, p3, p4)
    return [p1, p2, p3, p4, p1]
end


function interactive_plot_with_polygon_tool(ax, image)
    points = Observable(Point2f0[])
    mask_ready = Observable(false)
    mask = Observable(Point2f0[])
    
    on(events(ax.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            pos = mouseposition(ax.scene)
            if all(pos .>= 0) && all(pos .<= Point2f0(size(image)))
                push!(points[], pos)
                notify(points)
                scatter!(ax, [pos], color=:red, markersize=4)
                if length(points[]) == 4
                    polygon_points = get_polygon_points(points[][1], points[][2], points[][3], points[][4])
                    lines!(ax, polygon_points, color=:red, linewidth=2)
                    println("Coordinates of the polygon: ", polygon_points)
                    mask[] = polygon_points
                    println("The mask is: ", mask[])
                    points[] = []
                    notify(points)
                    mask_ready[] = true
                end
            end
        end
    end
    
    return points, mask, mask_ready
end


# Function to extract polygon data and points
function extract_polygon_data_and_points(smld, polygon_points, zoom)
    println("Polygon points: ", polygon_points)

    # Initialize empty arrays to store the localizations and their z-coordinates within the polygon
    global localizations = []
    global localizations_z = []

    # Iterate over each localization in smld.x and smld.y
    for i in 1:length(smld.x)
        # Scale the coordinates by zoom
        scaled_x = smld.x[i] * zoom
        scaled_y = smld.y[i] * zoom
        
        # Create a point from the scaled coordinates
        point = Point2f0(scaled_x, scaled_y)
        
        # Check if the localization is inside the polygon
        if inpolygon(point, polygon_points) != 0
            # If the localization is inside the polygon, add its coordinates to the localizations array
            push!(localizations, (smld.y[i], smld.x[i]))
            push!(localizations_z, smld.z[i])
        end
    end
    
    # Print the number of localizations inside the polygon
    println("Number of localizations inside the polygon: ", length(localizations))
    
    return localizations, localizations_z
end


# Function to render the image and enable interactive polygon drawing
function render_image(button)
    global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff

    if !isa(z_range, Tuple{Real, Real})
        error("z_range is not of the correct type. It should be a tuple of two real numbers.")
    end
    
    out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
    
    # Replace the previous image in the axis
    image!(image_axis, out', show_axes = false) # transpose out
    status_label.text = "Image rendered"

    # Enable mouse interaction
    points, mask, mask_ready = interactive_plot_with_polygon_tool(image_axis, out)

    # Observable to store points inside the polygon
    polygon_points_inside = Observable(Point2f0[])

    # Extract the data and points after the rectangle is defined
    on(mask_ready) do ready
        if ready
            localizations, localizations_z = extract_polygon_data_and_points(smld, mask[], zoom)
            polygon_points_inside[] = [Point2f0(loc[2] * zoom, loc[1] * zoom) for loc in localizations]
            println("Number of localizations inside the polygon: ", length(localizations))
            #println("Z-coordinates inside the polygon: ", localizations_z)
        else
            println("No polygon was defined.")
        end
    end

    # Plot the localizations inside the polygon as red cross markers
    on(polygon_points_inside) do points
        scatter!(image_axis, points, markersize=5, marker=:circle, color=:red)
    end
end


# GUI setup
fig = Figure(resolution = (800, 800))

# Create a central container for the label
label_layout = GridLayout()
fig[1, 1] = label_layout

# Add a label to display the status at the top, centered in the figure
status_label = Label(fig, text = "SR image visualization", halign = :center, valign = :center)
label_layout[1, 1] = status_label

# Create a grid layout for the render button at the bottom
button_layout = GridLayout()
fig[3, 1] = button_layout

# Create a button for rendering the image at the bottom center
render_button = Button(fig, label = "Render Image")
button_layout[1, 1] = render_button

# Add an Axis directly to the main figure for displaying the image
image_axis = GLMakie.Axis(fig, title = "Rendered Image", aspect = DataAspect())
fig[2, 1] = image_axis

# Adjust the layout to give more space to the image axis
fig.layout[1, 1] = label_layout
fig.layout[3, 1] = button_layout

# Adjust row and column sizes
fig.layout.rowsizes = [Relative(0.1), Relative(0.8), Relative(0.1)]
fig.layout.colsizes = [Relative(1.0)]

# Assign the callback to the render button
on(render_button.clicks) do _
    render_image(render_button)
end

display(fig)

# localizations_z
# localizations

#using CairoMakie
# Extract x, y, and z coordinates to plot histogram
x_coords = [point[2] for point in localizations]
y_coords = [point[1] for point in localizations]
z_coords = Float64.(localizations_z)
# Create a histogram plot
fig2 = Figure(resolution = (700, 500))
ax2 = CairoMakie.Axis(fig2[1, 1], title = "Histogram of z-localizations", xlabel = "z (nm)", 
xlabelfont = "sans-semibold", ylabel = "Counts", ylabelfont = "sans-semibold", xticksize = 15, yticksize = 15,
xticklabelsize = 15, yticklabelsize = 15)
ax2.xlabelsize = 15
ax2.ylabelsize = 15
hist!(ax2, localizations_z, bins = 70, color = 1, colormap = :tab10, colorrange = (1, 10), strokewidth = 0.4, strokecolor = :white)
#hist!(ax2, localizations_z, bins = 70, color = :blue, strokewidth = 0.4, strokecolor = :white)
fit_result = fit(Distributions.Normal, z_coords)
μ = fit_result.μ
σ = fit_result.σ

x = range(minimum(z_coords), stop = maximum(z_coords), length = 100)
y = pdf.(Distributions.Normal(μ, σ), x) * length(z_coords) * (maximum(z_coords) - minimum(z_coords)) / 70

# Construct the simple legend label for the Gaussian fit
label = "Gaussian fit: <d> = $(round(μ, digits=2)) nm, σ = $(round(σ, digits=2)) nm"
# label = "Gaussian fit: μ = $(round(μ, digits=2)) nm, σ = $(round(σ, digits=2)) nm"
#label = "Gaussian fit:\nμ = $(round(μ, digits=2)) nm\nσ = $(round(σ, digits=2)) nm" # on multiple lines
# Plot Gaussian fit as red line and add legend with mean and sigma
lines!(ax2, x, y, color = :red, linewidth = 4, label = label)
axislegend(ax2, position = :rt, legendfontsize = 50)  
# Output mean and sigma
println("Mean (μ): ", μ)
println("Standard Deviation (σ): ", σ)
display(fig2)
# Extract x, y, and z coordinates for 3D scatter plot
# x_coords = [point[2] for point in localizations]
# y_coords = [point[1] for point in localizations]
# z_coords = localizations_z
# # Create a 3D scatter plot
# fig2 = Figure(resolution = (800, 600))
# ax2 = CairoMakie.Axis3(fig2[1, 1], title = "Localizations 3D Scatter Plot", xlabel = "X", ylabel = "Y", zlabel = "Z")
# scatter!(ax2, x_coords, y_coords, z_coords, markersize = 5, color = :blue) 
# display(fig2)


#=======================================================================================================#

# Extract and Plot the smld.z within polygon and hist as separate fig
z_range = (quantile(loc_data["z"], 0.01), quantile(loc_data["z"], 0.99))

function get_polygon_points(p1, p2, p3, p4)
    return [p1, p2, p3, p4, p1]
end

function interactive_plot_with_polygon_tool(ax, image)
    points = Observable(Point2f0[])
    mask_ready = Observable(false)
    mask = Observable(Point2f0[])
    
    on(events(ax.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            pos = mouseposition(ax.scene)
            if all(pos .>= 0) && all(pos .<= Point2f0(size(image)))
                push!(points[], pos)
                notify(points)
                scatter!(ax, [pos], color=:red, markersize=4)
                if length(points[]) == 4
                    polygon_points = get_polygon_points(points[][1], points[][2], points[][3], points[][4])
                    lines!(ax, polygon_points, color=:red, linewidth=2)
                    println("Coordinates of the polygon: ", polygon_points)
                    mask[] = polygon_points
                    println("The mask is: ", mask[])
                    points[] = []
                    notify(points)
                    mask_ready[] = true
                end
            end
        end
    end
    
    return points, mask, mask_ready
end

function extract_polygon_data_and_points(smld, polygon_points, zoom)
    println("Polygon points: ", polygon_points)

    localizations = []
    localizations_z = []

    for i in 1:length(smld.x)
        scaled_x = smld.x[i] * zoom
        scaled_y = smld.y[i] * zoom
        point = Point2f0(scaled_x, scaled_y)
        if inpolygon(point, polygon_points) != 0
            push!(localizations, (smld.y[i], smld.x[i]))
            push!(localizations_z, smld.z[i])
        end
    end
    
    println("Number of localizations inside the polygon: ", length(localizations))
    
    return localizations, localizations_z
end

function render_image(button)
    global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff, image_axis, localizations_z

    if !isa(z_range, Tuple{Real, Real})
        error("z_range is not of the correct type. It should be a tuple of two real numbers.")
    end
    
    out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
    
    image!(image_axis, out', show_axes = false)
    status_label.text = "SR Image Rendered"

    points, mask, mask_ready = interactive_plot_with_polygon_tool(image_axis, out)

    on(mask_ready) do ready
        if ready
            localizations, localizations_z = extract_polygon_data_and_points(smld, mask[], zoom)
            println("Number of localizations inside the polygon: ", length(localizations))
        else
            println("No polygon was defined.")
        end
    end
end

fig = Figure(resolution = (1000, 800))

# Add the status label at the top
status_label = Label(fig, text = "SR Image Visualization", halign = :center, valign = :center)

# Define the axes and buttons
global image_axis = GLMakie.Axis(fig[2, 1], title = "Render Image Axis", width = 500, height = 450)
ax2 = GLMakie.Axis(fig[2, 2], title = "Histogram Axis", width = 400, height = 350)
render_button = Button(fig[3, 1], label = "Render Image")
hist_button = Button(fig[3, 2], label = "Plot Histogram")

# Add a label to display the Gaussian fit parameters
fit_params_label = Label(fig, text = "", halign = :left, valign = :top)

# Arrange elements in the layout
fig.layout.rowsizes = [Auto(0.1), Auto(1), Auto(0.1)]
fig.layout.colsizes = [Auto(1), Auto(1)]

# Add elements to the layout
fig[1, 1:2] = status_label
fig[2, 1] = image_axis
fig[2, 2] = ax2
fig[3, 1] = render_button
fig[3, 2] = hist_button
fig[4, 2] = fit_params_label

function plot_histogram(button)
    global localizations_z

    # Clear the axis completely
    empty!(ax2.scene)
    
    z_coords = Float64.(localizations_z)

    hist!(ax2, localizations_z, bins = 70, color = 1, colormap = :tab10, colorrange = (1, 10), strokewidth = 0.4, strokecolor = :white)
    fit_result = fit(Distributions.Normal, z_coords)
    μ = fit_result.μ
    σ = fit_result.σ

    x = range(minimum(z_coords), stop = maximum(z_coords), length = 100)
    y = pdf.(Distributions.Normal(μ, σ), x) * length(z_coords) * (maximum(z_coords) - minimum(z_coords)) / 70

    label = "Gaussian fit: <d> = $(round(μ, digits=2)) nm, σ = $(round(σ, digits=2)) nm"
    lines!(ax2, x, y, color = :red, linewidth = 4, label = label)

    #axislegend(ax2, position = :rt, legendfontsize = 15)

    # Update the fit parameters label
    fit_params_label.text = label

    println("Mean (μ): ", μ)
    println("Standard Deviation (σ): ", σ)
end

on(render_button.clicks) do _
    render_image(render_button)
end

on(hist_button.clicks) do _
    plot_histogram(hist_button)
end

display(fig)





#==============================================================================================================================#

# create a mask on the rendered image by plotting the rectangle on the image. The mask should be: 
# mask = (smld.x > xₘᵢₙ) & (smld.x < xₘₐₓ) & (smld.y > yₘᵢₙ) & (smld.y < yₘₐₓ) 
# where xₘᵢₙ, xₘₐₓ, yₘᵢₙ, yₘₐₓ are the minimum and maximum x and y values of the rectangle, respectively. 

# Example mask
# mask = [Point2f0(1212.2068, 2258.8857), 
#         Point2f0(1587.8201, 2333.2522), 
#         Point2f0(1833.0552, 1921.1372), 
#         Point2f0(1538.1522, 1803.3901)]

# Extract x and y coordinates
x_coords = [point[1] for point in mask]
y_coords = [point[2] for point in mask]

# Find the minimum and maximum values
x_min = minimum(x_coords)
x_max = maximum(x_coords)
y_min = minimum(y_coords)
y_max = maximum(y_coords)

println("X range: ($x_min, $x_max)")
println("Y range: ($y_min, $y_max)")

filtered_locs = (smld.x .> x_min) .& (smld.x .< x_max) .& (smld.y .> y_min) .& (smld.y .< y_max)
xs = smld.x[filtered_locs]
zs = smld.z[filtered_locs]



# Additional functionality
# Function to read the keys of a .jld2 file
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



#==============================================================================================================================#
# In this aprt hist legend not gets updated:

function get_polygon_points(p1, p2, p3, p4)
    return [p1, p2, p3, p4, p1]
end

function interactive_plot_with_polygon_tool(ax, image)
    points = Observable(Point2f0[])
    mask_ready = Observable(false)
    mask = Observable(Point2f0[])
    
    on(events(ax.scene).mousebutton) do event
        if event.button == Mouse.left && event.action == Mouse.press
            pos = mouseposition(ax.scene)
            if all(pos .>= 0) && all(pos .<= Point2f0(size(image)))
                push!(points[], pos)
                notify(points)
                scatter!(ax, [pos], color=:red, markersize=4)
                if length(points[]) == 4
                    polygon_points = get_polygon_points(points[][1], points[][2], points[][3], points[][4])
                    lines!(ax, polygon_points, color=:red, linewidth=2)
                    println("Coordinates of the polygon: ", polygon_points)
                    mask[] = polygon_points
                    println("The mask is: ", mask[])
                    points[] = []
                    notify(points)
                    mask_ready[] = true
                end
            end
        end
    end
    
    return points, mask, mask_ready
end

function extract_polygon_data_and_points(smld, polygon_points, zoom)
    println("Polygon points: ", polygon_points)

    localizations = []
    localizations_z = []

    for i in 1:length(smld.x)
        scaled_x = smld.x[i] * zoom
        scaled_y = smld.y[i] * zoom
        point = Point2f0(scaled_x, scaled_y)
        if inpolygon(point, polygon_points) != 0
            push!(localizations, (smld.y[i], smld.x[i]))
            push!(localizations_z, smld.z[i])
        end
    end
    
    println("Number of localizations inside the polygon: ", length(localizations))
    
    return localizations, localizations_z
end

function render_image(button)
    global smld, normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff, image_axis, localizations_z

    if !isa(z_range, Tuple{Real, Real})
        error("z_range is not of the correct type. It should be a tuple of two real numbers.")
    end
    
    out, (cm, z_range) = SMLMVis.render_blobs(smld; normalization, n_sigmas, colormap, z_range, zoom, percentile_cutoff)
    
    image!(image_axis, out', show_axes = false)
    status_label.text = "Image rendered"

    points, mask, mask_ready = interactive_plot_with_polygon_tool(image_axis, out)

    on(mask_ready) do ready
        if ready
            localizations, localizations_z = extract_polygon_data_and_points(smld, mask[], zoom)
            println("Number of localizations inside the polygon: ", length(localizations))
        else
            println("No polygon was defined.")
        end
    end
end

fig = Figure(resolution = (1000, 800))

# Add the status label at the top
status_label = Label(fig, text = "SR image visualization", halign = :center, valign = :center)

# Define the axes and buttons
global image_axis = GLMakie.Axis(fig[2, 1], title = "Render Image Axis", width = 500, height = 450)
ax2 = GLMakie.Axis(fig[2, 2], title = "Histogram Axis", width = 400, height = 350)
render_button = Button(fig[3, 1], label = "Render Image")
hist_button = Button(fig[3, 2], label = "Plot Histogram")

# Arrange elements in the layout
fig.layout.rowsizes = [Auto(0.1), Auto(1), Auto(0.1)]
fig.layout.colsizes = [Auto(1), Auto(1)]

# Add elements to the layout
fig[1, 1:2] = status_label
fig[2, 1] = image_axis
fig[2, 2] = ax2
fig[3, 1] = render_button
fig[3, 2] = hist_button

function plot_histogram(button)
    global localizations_z

    empty!(ax2.scene)
    
    z_coords = Float64.(localizations_z)

    hist!(ax2, localizations_z, bins = 70, color = 1, colormap = :tab10, colorrange = (1, 10), strokewidth = 0.4, strokecolor = :white)
    fit_result = fit(Distributions.Normal, z_coords)
    μ = fit_result.μ
    σ = fit_result.σ

    x = range(minimum(z_coords), stop = maximum(z_coords), length = 100)
    y = pdf.(Distributions.Normal(μ, σ), x) * length(z_coords) * (maximum(z_coords) - minimum(z_coords)) / 70

    label = "Gaussian fit: <d> = $(round(μ, digits=2)) nm, σ = $(round(σ, digits=2)) nm"
    lines!(ax2, x, y, color = :red, linewidth = 4, label = label)

    axislegend(ax2, position = :rt, legendfontsize = 15)

    println("Mean (μ): ", μ)
    println("Standard Deviation (σ): ", σ)
end

on(render_button.clicks) do _
    render_image(render_button)
end

on(hist_button.clicks) do _
    plot_histogram(hist_button)
end

display(fig)
